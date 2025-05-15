import java.rmi.Remote;
import java.rmi.RemoteException;
import java.rmi.server.UnicastRemoteObject;

public class BindObject extends UnicastRemoteObject implements CustomRemote {
    protected BindObject() throws RemoteException {
        super();
    }
    public String sayHello() throws RemoteException {
        return "Hello, world!";
    }
}
