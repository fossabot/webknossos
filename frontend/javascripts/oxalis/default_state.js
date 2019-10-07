// @flow

import type { OxalisState } from "oxalis/store";
import Constants, { ControlModeEnum, OrthoViews } from "oxalis/constants";

const defaultViewportRect = {
  top: 0,
  left: 0,
  width: Constants.VIEWPORT_WIDTH,
  height: Constants.VIEWPORT_WIDTH,
};

export const defaultDiameterProperties = {
  xRadius: 20,
  yRadius: 20,
  scaledXRadius: 20,
  scaledYRadius: 20,
  rotationAngle: 0,
};

const initialAnnotationInfo = {
  annotationId: "",
  restrictions: {
    branchPointsAllowed: false,
    allowUpdate: false,
    allowFinish: false,
    allowAccess: true,
    allowDownload: false,
    somaClickingAllowed: false,
    mergerMode: false,
    allowedModes: ["orthogonal", "oblique", "flight"],
  },
  isPublic: false,
  tags: [],
  description: "",
  name: "",
  tracingStore: {
    name: "localhost",
    url: "http://localhost:9000",
  },
  annotationType: "View",
  meshes: [],
};

const defaultState: OxalisState = {
  datasetConfiguration: {
    fourBit: false,
    interpolation: false,
    layers: {},
    quality: 0,
    isSegmentationDisabled: false,
    loadingStrategy: "PROGRESSIVE_QUALITY",
    segmentationOpacity: 20,
    highlightHoveredCellId: true,
    renderIsosurfaces: false,
    renderMissingDataBlack: true,
  },
  userConfiguration: {
    autoSaveLayouts: true,
    brushSize: 50,
    clippingDistance: 50,
    clippingDistanceArbitrary: 64,
    showDiameter: false,
    crosshairSize: 0.1,
    displayCrosshair: true,
    displayScalebars: true,
    dynamicSpaceDirection: true,
    hideTreeRemovalWarning: false,
    highlightCommentedNodes: false,
    keyboardDelay: 200,
    layoutScaleValue: 1,
    mouseRotateValue: 0.004,
    moveValue3d: 300,
    moveValue: 300,
    newNodeNewTree: false,
    overrideNodeRadius: true,
    particleSize: 5,
    radius: 5,
    rotateValue: 0.01,
    sortCommentsAsc: true,
    sortTreesByName: false,
    sphericalCapRadius: Constants.DEFAULT_SPHERICAL_CAP_RADIUS,
    tdViewDisplayPlanes: true,
    gpuMemoryFactor: Constants.DEFAULT_GPU_MEMORY_FACTOR,
  },
  temporaryConfiguration: {
    viewMode: Constants.MODE_PLANE_TRACING,
    flightmodeRecording: false,
    controlMode: ControlModeEnum.VIEW,
    diameterProperties: defaultDiameterProperties,
    mousePosition: null,
    hoveredIsosurfaceId: 0,
    activeMapping: {
      mappingName: null,
      mapping: null,
      mappingKeys: null,
      mappingColors: null,
      hideUnmappedIds: false,
      isMappingEnabled: false,
      mappingSize: 0,
    },
    isMergerModeEnabled: false,
    isAutoBrushEnabled: false,
    gpuSetup: {
      smallestCommonBucketCapacity:
        Constants.GPU_FACTOR_MULTIPLIER * Constants.DEFAULT_GPU_MEMORY_FACTOR,
      initializedGpuFactor: Constants.GPU_FACTOR_MULTIPLIER,
    },
  },
  task: null,
  dataset: {
    name: "Test Dataset",
    isUnreported: false,
    created: 123,
    dataSource: {
      dataLayers: [],
      scale: [5, 5, 5],
      id: {
        name: "Test Dataset",
        team: "",
      },
    },
    details: null,
    isPublic: false,
    isActive: true,
    isEditable: true,
    dataStore: {
      name: "localhost",
      url: "http://localhost:9000",
      isScratch: false,
      isForeign: false,
      isConnector: false,
    },
    owningOrganization: "Connectomics department",
    description: null,
    displayName: "Awesome Test Dataset",
    allowedTeams: [],
    logoUrl: null,
    lastUsedByUser: 0,
    isForeign: false,
    sortingKey: 123,
    publication: null,
  },
  tracing: {
    ...initialAnnotationInfo,
    readOnly: {
      boundingBox: null,
      createdTimestamp: 0,
      userBoundingBox: null,
      type: "readonly",
      version: 0,
      tracingId: "",
    },
    volume: null,
    skeleton: null,
    user: null,
  },
  save: {
    queue: {
      skeleton: [],
      volume: [],
    },
    isBusyInfo: {
      skeleton: false,
      volume: false,
    },
    lastSaveTimestamp: 0,
    progressInfo: {
      processedActionCount: 0,
      totalActionCount: 0,
    },
  },
  flycam: {
    zoomStep: 1.3,
    currentMatrix: [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
    spaceDirectionOrtho: [1, 1, 1],
    direction: [0, 0, 0],
  },
  viewModeData: {
    plane: {
      activeViewport: OrthoViews.PLANE_XY,
      tdCamera: {
        near: 0,
        far: 0,
        left: 0,
        right: 0,
        top: 0,
        bottom: 0,
        up: [0, 0, 0],
        lookAt: [0, 0, 0],
        position: [0, 0, 0],
      },
      inputCatcherRects: {
        PLANE_XY: defaultViewportRect,
        PLANE_YZ: defaultViewportRect,
        PLANE_XZ: defaultViewportRect,
        TDView: defaultViewportRect,
      },
    },
    arbitrary: {
      inputCatcherRect: defaultViewportRect,
    },
  },
  activeUser: null,
  uiInformation: {
    showDropzoneModal: false,
    showVersionRestore: false,
    storedLayouts: {},
    isImportingMesh: false,
    isInAnnotationView: false,
    hasOrganizations: false,
  },
};

export default defaultState;
