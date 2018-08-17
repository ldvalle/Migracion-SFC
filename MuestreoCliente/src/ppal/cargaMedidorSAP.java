package ppal;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Scanner;
import dao.DeviceDAO;

public class cargaMedidorSAP {

	public static void main(String[] args) {

		ProcesaFiles();
	}

	
	private static void ProcesaFiles() {
		File f = new File("C:\\Users\\ar17031095.ENELINT\\Documents\\MAC\\MIGRACION\\SAP\\backUps\\medidores_sel\\medid.txt");
		
		Scanner s;
		String sLinea;
		DeviceDAO miDao = new DeviceDAO();
		
		try {
			s = new Scanner(f);
			while (s.hasNextLine()) {
				String linea = s.nextLine();
				String sLineaAux="";
				String NroMedidor="";
				String MarcaMedidor="";
				String ModeloMedidor="";
				
				sLineaAux = linea.substring(2, linea.length());
				
				NroMedidor = sLineaAux.substring(0, sLineaAux.length()-5);
				MarcaMedidor = sLineaAux.substring(NroMedidor.length(), NroMedidor.length()+3);
				ModeloMedidor = sLineaAux.substring(sLineaAux.length()-2, sLineaAux.length());
				
				//System.out.println(String.format("Linea %s Nro %s Marca %s Modelo %s", sLineaAux, NroMedidor, MarcaMedidor, ModeloMedidor));
				
				if(!miDao.setLstMedidores(NroMedidor, MarcaMedidor, ModeloMedidor)) {
					System.out.println("Error al insertar Medidor " + NroMedidor + " Marca " + MarcaMedidor + " Modelo " + ModeloMedidor);
				}
			}
			s.close();
			System.out.println("Proceso Terminado");
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		}
		
	}
	
}
