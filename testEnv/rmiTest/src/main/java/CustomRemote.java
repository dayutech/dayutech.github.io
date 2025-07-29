import java.rmi.Remote;
import java.rmi.RemoteException;

public interface CustomRemote extends Remote {
    public String sayHello() throws RemoteException;
}
