package servicios;

import dao.universoDAO;

public class universoSRV {

	public Boolean CargaUniversoSAP() {
		int i=1;
		int iTope=20;
		
		universoDAO miDAO = new universoDAO();
		
		
		for(i=1; i<= iTope; i++) {
			System.out.println("Vuelta " + i);
			if(! miDAO.CargaUniverso()) {
				System.out.println("Fallo carga de universo.");
				return false;
			}
		}
		
		return true;
	}
	
}
