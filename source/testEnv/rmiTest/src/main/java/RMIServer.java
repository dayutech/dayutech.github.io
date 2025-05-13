import java.rmi.AlreadyBoundException;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

public class RMIServer {
    public static void main(String[] args) throws RemoteException, AlreadyBoundException {
        BindObject bindObject = new BindObject();
        Registry registry = LocateRegistry.createRegistry(1099);
        registry.bind("test", bindObject);
    }
}
