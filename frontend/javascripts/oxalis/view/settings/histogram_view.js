// @flow

import { Slider } from "antd";
import memoizeOne from "memoize-one";
import * as _ from "lodash";
import * as React from "react";
import type { Dispatch } from "redux";
import { connect } from "react-redux";
import { type DatasetLayerConfiguration } from "oxalis/store";
import { updateLayerSettingAction } from "oxalis/model/actions/settings_actions";
import { type ElementClass } from "admin/api_flow_types";
import type { APIHistogramData } from "admin/api_flow_types";
import { type Vector3 } from "oxalis/constants";
import { roundTo } from "libs/utils";

type OwnProps = {|
  data: APIHistogramData,
  layerName: string,
  min: number,
  max: number,
|};

type HistogramProps = {
  ...OwnProps,
  onChangeLayer: (
    layerName: string,
    propertyName: $Keys<DatasetLayerConfiguration>,
    value: [number, number],
  ) => void,
};

const uint24Colors = [[255, 65, 54], [46, 204, 64], [24, 144, 255]];
const canvasHeight = 100;
const canvasWidth = 280;
const sliderHeight = 30;

export function isHistogramSupported(elementClass: ElementClass): boolean {
  return ["int8", "uint8", "int16", "uint16", "float", "uint24"].includes(elementClass);
}

class Histogram extends React.PureComponent<HistogramProps> {
  canvasRef: ?HTMLCanvasElement;

  getMaximumValue = memoizeOne((data: APIHistogramData) =>
    Math.max(...data.map(({ elementCounts }) => Math.max(...elementCounts))),
  );

  componentDidMount() {
    if (this.canvasRef == null) {
      return;
    }
    const ctx = this.canvasRef.getContext("2d");
    ctx.translate(0, canvasHeight);
    ctx.scale(1, -1);
    ctx.lineWidth = 1;
    ctx.lineJoin = "round";
    this.updateCanvas();
  }

  componentDidUpdate() {
    this.updateCanvas();
  }

  updateCanvas() {
    if (this.canvasRef == null) {
      return;
    }
    const ctx = this.canvasRef.getContext("2d");
    ctx.clearRect(0, 0, canvasWidth, canvasHeight);
    const { data } = this.props;
    // Compute the overall maximum count, so the RGB curves are scaled correctly relative to each other
    const maxValue = this.getMaximumValue(data);
    for (const [i, histogram] of data.entries()) {
      const color = this.props.data.length > 1 ? uint24Colors[i] : uint24Colors[2];
      this.drawHistogram(ctx, histogram, maxValue, color);
    }
  }

  drawHistogram = (
    ctx: CanvasRenderingContext2D,
    histogram: $ElementType<APIHistogramData, number>,
    maxValue: number,
    color: Vector3,
  ) => {
    const { min, max } = this.props;
    const { min: minRange, max: maxRange, elementCounts } = histogram;
    const rangeLength = maxRange - minRange;
    ctx.fillStyle = `rgba(${color.join(",")}, 0.1)`;
    ctx.strokeStyle = `rgba(${color.join(",")})`;
    const downscaledData = elementCounts.map(value =>
      value > 0 ? (Math.log(value) / Math.log(maxValue)) * canvasHeight : 0,
    );
    const activeRegion = new Path2D();
    ctx.beginPath();
    ctx.moveTo(0, downscaledData[0]);
    activeRegion.moveTo(((min - minRange) / rangeLength) * canvasWidth, 0);
    for (let i = 0; i < downscaledData.length; i++) {
      const x = (i / downscaledData.length) * canvasWidth;
      const xValue = minRange + i * (rangeLength / downscaledData.length);
      if (xValue >= min && xValue <= max) {
        activeRegion.lineTo(x, downscaledData[i]);
      }
      ctx.lineTo(x, downscaledData[i]);
    }
    ctx.stroke();
    ctx.closePath();
    activeRegion.lineTo(((max - minRange) / rangeLength) * canvasWidth, 0);
    activeRegion.lineTo(((min - minRange) / rangeLength) * canvasWidth, 0);
    activeRegion.closePath();
    ctx.fill(activeRegion);
  };

  onThresholdChange = ([firstVal, secVal]: [number, number]) => {
    const { layerName } = this.props;
    if (firstVal < secVal) {
      this.props.onChangeLayer(layerName, "intensityRange", [firstVal, secVal]);
    } else {
      this.props.onChangeLayer(layerName, "intensityRange", [secVal, firstVal]);
    }
  };

  render() {
    const { min, max, data } = this.props;
    const { min: minRange, max: maxRange } = data[0];
    const maxValue = this.getMaximumValue(data);
    const middleValue = Math.round(Math.pow(Math.E, Math.log(maxValue) / 2));
    return (
      <React.Fragment>
        <div
          style={{
            display: "flex",
            flexDirection: "row",
          }}
        >
          <div
            style={{
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between",
              paddingBottom: sliderHeight,
              textAlign: "right",
              fontSize: 12,
            }}
          >
            <div>{maxValue}</div>
            <div>{middleValue}</div>
            <div>0</div>
          </div>
          <div style={{ height: "100%", display: "inline-block", width: canvasWidth }}>
            <canvas
              ref={ref => {
                this.canvasRef = ref;
              }}
              width={250}
              height={canvasHeight}
            />
            <Slider
              value={[min, max]}
              min={minRange}
              max={maxRange}
              range
              defaultValue={[minRange, maxRange]}
              onChange={this.onThresholdChange}
              onAfterChange={this.onThresholdChange}
              style={{ width: "100%", margin: 0, marginBottom: 18 }}
              step={(maxRange - minRange) / 255}
              tipFormatter={val => roundTo(val, 2).toString()}
            />
          </div>
        </div>
      </React.Fragment>
    );
  }
}

const mapDispatchToProps = (dispatch: Dispatch<*>) => ({
  onChangeLayer(layerName, propertyName, value) {
    dispatch(updateLayerSettingAction(layerName, propertyName, value));
  },
});

export default connect<HistogramProps, OwnProps, _, _, _, _>(
  null,
  mapDispatchToProps,
)(Histogram);
