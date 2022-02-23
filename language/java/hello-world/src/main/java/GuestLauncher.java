import com.oracle.svm.graalvisor.guestapi.GuestAPI;

import java.lang.reflect.InvocationTargetException;

/**
 * Function launcher that helps to collect necessary configurations using tracing agent. Guest
 * application itself is invoked by reflection as well.
 */
public class GuestLauncher extends GuestAPI {
    public static void main(String args[]) {
        String applicationClassName = args[0];
        String arguments = args[1];
        try {
            setApplicationClassName(applicationClassName);
            invoke(arguments);
        } catch (ClassNotFoundException | NoSuchMethodException | InvocationTargetException | IllegalAccessException e) {
            e.printStackTrace();
        }
    }
}
