// @flow
import _ from "lodash";

import { document } from "libs/window";
import constants, { type Vector3 } from "oxalis/constants";
import { type ElementClass } from "admin/api_flow_types";

type GpuSpecs = {
  supportedTextureSize: number,
  maxTextureCount: number,
};

export function getSupportedTextureSpecs(): GpuSpecs {
  const canvas = document.createElement("canvas");
  const contextProvider = canvas.getContext
    ? x => canvas.getContext(x)
    : ctxName => ({
        MAX_TEXTURE_SIZE: 0,
        MAX_COMBINED_TEXTURE_IMAGE_UNITS: 1,
        getParameter(param) {
          return ctxName === "webgl" && param === 0 ? 4096 : 8192;
        },
      });

  const gl = contextProvider("webgl");

  if (!gl) {
    throw new Error("WebGL context could not be constructed.");
  }

  const supportedTextureSize = gl.getParameter(gl.MAX_TEXTURE_SIZE);
  const maxTextureCount = gl.getParameter(gl.MAX_COMBINED_TEXTURE_IMAGE_UNITS);

  return { supportedTextureSize, maxTextureCount };
}

export function validateMinimumRequirements(specs: GpuSpecs): void {
  if (specs.supportedTextureSize < 4096 || specs.maxTextureCount < 8) {
    throw new Error(
      "Minimum spec is not met. GPU should support at least a texture size of 4096 and 8 textures.",
    );
  }
}

export type DataTextureSizeAndCount = {|
  textureSize: number,
  textureCount: number,
  packingDegree: number,
|};

export function getPackingDegree(byteCount: number, elementClass: ElementClass) {
  // If the layer holds less than 4 byte per voxel, we can pack multiple voxels using rgba channels
  // Float textures can hold a float per channel, adjust the packing degree accordingly
  if (byteCount === 1 || elementClass === "float") return 4;
  if (byteCount === 2) return 2;
  return 1;
}

export function getChannelCount(
  byteCount: number,
  packingDegree: number,
  elementClass: ElementClass,
) {
  if (elementClass === "float") {
    // Float textures can hold a float per channel, so divide bytes by 4
    return (byteCount / 4) * packingDegree;
  } else {
    return byteCount * packingDegree;
  }
}

export function getBucketCapacity(
  dataTextureCount: number,
  textureWidth: number,
  packingDegree: number,
): number {
  return (packingDegree * dataTextureCount * textureWidth ** 2) / constants.BUCKET_SIZE;
}

function getNecessaryVoxelCount(requiredBucketCapacity) {
  return requiredBucketCapacity * constants.BUCKET_SIZE;
}

function getAvailableVoxelCount(textureSize: number, packingDegree: number) {
  return packingDegree * textureSize ** 2;
}

function getTextureCount(
  textureSize: number,
  packingDegree: number,
  requiredBucketCapacity: number,
) {
  return Math.ceil(
    getNecessaryVoxelCount(requiredBucketCapacity) /
      getAvailableVoxelCount(textureSize, packingDegree),
  );
}

export function calculateTextureSizeAndCountForLayer(
  specs: GpuSpecs,
  byteCount: number,
  elementClass: ElementClass,
  requiredBucketCapacity: number,
): DataTextureSizeAndCount {
  let textureSize = specs.supportedTextureSize;
  const packingDegree = getPackingDegree(byteCount, elementClass);

  // Try to half the texture size as long as it does not require more
  // data textures
  while (
    getTextureCount(textureSize / 2, packingDegree, requiredBucketCapacity) <=
    getTextureCount(textureSize, packingDegree, requiredBucketCapacity)
  ) {
    textureSize /= 2;
  }

  const textureCount = getTextureCount(textureSize, packingDegree, requiredBucketCapacity);
  return { textureSize, textureCount, packingDegree };
}

function buildTextureInformationMap<Layer: { elementClass: ElementClass }>(
  layers: Array<Layer>,
  getByteCountForLayer: Layer => number,
  specs: GpuSpecs,
  requiredBucketCapacity: number,
): Map<Layer, DataTextureSizeAndCount> {
  const textureInformationPerLayer = new Map();

  layers.forEach(layer => {
    const sizeAndCount = calculateTextureSizeAndCountForLayer(
      specs,
      getByteCountForLayer(layer),
      layer.elementClass,
      requiredBucketCapacity,
    );
    textureInformationPerLayer.set(layer, sizeAndCount);
  });

  return textureInformationPerLayer;
}

function calculateNecessaryTextureCount<Layer>(
  textureInformationPerLayer: Map<Layer, DataTextureSizeAndCount>,
): number {
  const layers = Array.from(textureInformationPerLayer.values());
  const totalDataTextureCount = _.sum(layers.map(info => info.textureCount));

  const lookupTextureCountPerLayer = 1;
  const necessaryTextureCount = layers.length * lookupTextureCountPerLayer + totalDataTextureCount;

  return necessaryTextureCount;
}

function calculateMappingTextureCount(): number {
  // If there is a segmentation layer, we need one lookup, one data and one color texture for mappings
  const textureCountForCellMappings = 3;
  return textureCountForCellMappings;
}

function deriveSupportedFeatures<Layer>(
  specs: GpuSpecs,
  textureInformationPerLayer: Map<Layer, DataTextureSizeAndCount>,
  hasSegmentation: boolean,
): { isMappingSupported: boolean, isBasicRenderingSupported: boolean } {
  const necessaryTextureCount = calculateNecessaryTextureCount(textureInformationPerLayer);

  let isMappingSupported = true;
  let isBasicRenderingSupported = true;

  if (necessaryTextureCount > specs.maxTextureCount) {
    isBasicRenderingSupported = false;
  }

  // Count textures needed for mappings separately, because they are not strictly necessary
  const notEnoughTexturesForMapping =
    necessaryTextureCount + calculateMappingTextureCount() > specs.maxTextureCount;
  if (hasSegmentation && notEnoughTexturesForMapping) {
    // Only mark mappings as unsupported if a segmentation exists
    isMappingSupported = false;
  }

  return {
    isMappingSupported,
    isBasicRenderingSupported,
  };
}

function getSmallestCommonBucketCapacity(textureInformationPerLayer): number {
  const capacities = Array.from(textureInformationPerLayer.values()).map(
    (sizeAndCount: DataTextureSizeAndCount) =>
      getBucketCapacity(
        sizeAndCount.textureCount,
        sizeAndCount.textureSize,
        sizeAndCount.packingDegree,
      ),
  );

  return _.min(capacities);
}

export function computeDataTexturesSetup<Layer>(
  specs: GpuSpecs,
  // $FlowFixMe
  layers: Array<Layer>,
  getByteCountForLayer: Layer => number,
  hasSegmentation: boolean,
  requiredBucketCapacity: number,
): * {
  const textureInformationPerLayer = buildTextureInformationMap(
    layers,
    getByteCountForLayer,
    specs,
    requiredBucketCapacity,
  );
  const smallestCommonBucketCapacity = getSmallestCommonBucketCapacity(textureInformationPerLayer);

  const { isBasicRenderingSupported, isMappingSupported } = deriveSupportedFeatures(
    specs,
    textureInformationPerLayer,
    hasSegmentation,
  );

  return {
    isBasicRenderingSupported,
    isMappingSupported,
    textureInformationPerLayer,
    smallestCommonBucketCapacity,
  };
}

export function getGpuFactorsWithLabels() {
  return [["12", "Very High"], ["6", "High"], ["3", "Medium"], ["1", "Low"]];
}

export function getLookupBufferSize(gpuMultiplier: number): number {
  switch (gpuMultiplier) {
    case 1:
    case 3:
      return 256;
    case 6:
      return 512;
    case 12:
      return 1024;
    default:
      return 512;
  }
}

// A look up buffer with the size [key]**2 is able to represent
// a volume with the dimensions of [value].
// The values were chosen so that value[0]*value[1]*value[2] / key**2
// approaches ~ 1 (i.e., the utilization ratio of the buffer is close to
// 100%).
const addressSpaceDimensionsTable = {
  "256": [36, 36, 50],
  "512": [61, 61, 70],
  "1024": [96, 96, 112],
};

export function getAddressSpaceDimensions(gpuMultiplier: number): Vector3 {
  const lookupBufferSize = getLookupBufferSize(gpuMultiplier);
  return addressSpaceDimensionsTable[lookupBufferSize] || addressSpaceDimensionsTable["256"];
}
