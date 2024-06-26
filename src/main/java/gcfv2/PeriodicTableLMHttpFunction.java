package gcfv2;

import java.io.BufferedWriter;
import java.io.IOException;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.StringTokenizer;
import java.util.stream.Collectors;

import com.google.cloud.functions.HttpFunction;
import com.google.cloud.functions.HttpRequest;
import com.google.cloud.functions.HttpResponse;


public class PeriodicTableLMHttpFunction implements HttpFunction {

  public String random(BufferedWriter writer, String input) throws java.lang.Exception {
	  
	List<String> strings = Collections.list(new StringTokenizer(input, ",")).stream()
		.map(token -> (String) token)
		.collect(Collectors.toList());
		
	// search each single and double character combination - if not in PT map - use a stub
	
    int index = (int)(Math.random() * strings.size());
    writer.write("{key: " + index + ", ");
		return strings.get(index);
  }

  public void service(final HttpRequest request, final HttpResponse response) throws java.lang.Exception, IOException {
    final BufferedWriter writer = response.getWriter();
    Optional<String> aCSVString = request.getFirstQueryParameter("list");
    if(aCSVString.isPresent()) {
      writer.write("value: " + random(writer, aCSVString.get()) + "}");
    } else {
      writer.write("append to the url ?list=first,second,third....to get a random indexed string back in json");
    }
  }
}
