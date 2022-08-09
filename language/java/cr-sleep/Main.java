import com.google.gson.JsonObject;
import java.lang.InterruptedException;

public class Main {
    public static JsonObject main(JsonObject args) {
        JsonObject response = new JsonObject();
        try {
            long millis = args.getAsJsonPrimitive("sleep").getAsLong();
            Thread.sleep(millis);
        } catch (InterruptedException ie) {
            response.addProperty("output", "InterruptedException");
        }
        return response;
    }
}
