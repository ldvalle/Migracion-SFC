package servicios;

import entidades.ClienteDTO;
import dao.ClientesDAO;
import java.util.Collection;

public class ClienteSRV {

	public Boolean getListaClientes(){
		Collection<ClienteDTO> lstClientes = null;
		
		ClientesDAO miDao = new ClientesDAO();
		
		lstClientes = miDao.getLstClientes();
		
		for(ClienteDTO miClie : lstClientes){
			
			if(ValidacionOK(miClie)){
				
				//Grabar Cliente
			}
		}
		
		return true;
	}
	
	private Boolean ValidacionOK( ClienteDTO miReg){
		
		if(miReg.sucursal != "0004")
			return false;
			
		return true;
	}
	
	
	
}
