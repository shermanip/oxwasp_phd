import ij.ImageJ;
import ij.ImagePlus;
import ij.process.FloatProcessor;
import org.apache.commons.math3.random.MersenneTwister;

public class Global {
  
  public static void main(String[] args) {
    
    System.out.println("Hello");
    
    ImageJ.main(null);
    FloatProcessor processorOrginal = new FloatProcessor(255, 250);
    MersenneTwister rng = new MersenneTwister(1018526);
    for (int i=0; i<processorOrginal.getPixelCount(); i++) {
      processorOrginal.setf(i, (float) rng.nextGaussian());
    }
    
    ImagePlus image = new ImagePlus("float version" , processorOrginal);
    
    double radius = 20;
    
    ImagePlus org = image.duplicate();
    org.show();
    
    long time = System.currentTimeMillis();
    
    Empirical_Null_Filter filter = new Empirical_Null_Filter();
    filter.setup(null, image);
    filter.setRadius(radius);
    filter.setOutputImage(63);
    filter.run(image.getProcessor());
    image.show();
    
    System.out.println("time "+(System.currentTimeMillis() - time) + " ms");
    
  }
  
}
