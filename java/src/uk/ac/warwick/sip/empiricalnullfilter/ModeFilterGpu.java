//MIT License
//Copyright (c) 2020 Sherman Lo

package uk.ac.warwick.sip.empiricalnullfilter;

import ij.IJ;
import ij.gui.GenericDialog;
import ij.process.ImageProcessor;

public class ModeFilterGpu extends EmpiricalNullFilterGpu {

  //CONSTRUCTOR
  public ModeFilterGpu() {
    this.outputImagePointer = 0;
    this.n_image_output = 0;
    this.flags = DOES_ALL + CONVERT_TO_FLOAT;
  }

  //IMPLEMENTED: RUN
  /**For the use of ExtendedPlugInFilter. Do the filtering.
   * @param ip image to be filtered
   */
  @Override
  public void run(ImageProcessor ip) {
    //save the image
    this.imageProcessor = ip;
    //do the filtering
    this.filter();
    //interrupted by user?
    if (IJ.escapePressed()) {
      ip.reset();
    }
  }

  //resulting image is the mode
  @Override
  protected void updatePixelInImage(float [] values, int valuesP, float [] nullMeanStd) {
    values[valuesP] = nullMeanStd[0];
  }

}