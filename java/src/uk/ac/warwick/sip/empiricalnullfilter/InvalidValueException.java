package uk.ac.warwick.sip.empiricalnullfilter;

//CLASS: INVALID VALUE EXCEPTION
/**To be thrown if the user input an invalid value
 */
public class InvalidValueException extends Exception{

  public InvalidValueException() {
    super();
  }
  
  public InvalidValueException(String string) {
    super(string);
  }
  
}