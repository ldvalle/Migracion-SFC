package servicios;

import java.util.*;
//import java.util.Collection;
//import java.util.Vector;

import javax.management.openmbean.OpenMBeanOperationInfoSupport;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.charset.Charset;
import java.nio.file.Files;	
import java.nio.file.Path;
import java.nio.file.Paths;
import static java.nio.file.StandardOpenOption.*;

import entidades.*;
import dao.*;


public class sfcContrato {

	public Boolean genContratoSFC(String sOS) {
		Collection<sfcClienteDTO> miLista = null;
		ClientesDAO miDao = new ClientesDAO();

		System.out.println("Tabla de Caracteres: " + System.getProperty("file.encoding"));
		
		try {

			//Writer out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream("c:\\fileUTF.txt"), "UTF-8"));
			//BufferedWriter out = Files.newBufferedWriter("c:\\fileUTF.txt", StandardCharsets.UTF_8);
			Writer out =null;
			if(sOS.compareTo("DOS")==0) {
				out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream("c:\\fileUTF.txt"), StandardCharsets.UTF_8));
			}else {
				out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream("/home/ldvalle/noti_out/fileUTF.txt"), "UTF-8"));
			}

			miLista = miDao.getLstSfcCliente();
			for(sfcClienteDTO fila : miLista) {
				
				GeneraPlano(out, fila);
			}
			out.close();
			
		}catch(Exception 	e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
	private void GeneraPlano(Writer out, sfcClienteDTO fila) {
		String sLinea;
		
		//CurrencyIsoCode
		sLinea = "\"AR$\";";
		//ContractTerm
		sLinea += "\"9999\";";
		//Status
		sLinea += "\"Activated\";";
		//EndDate
		sLinea += "\"9999-12-31\";";
		//Name
		sLinea += "\"" + fila.numero_cliente + "\";";
		//Nombre del contrato
		sLinea += "\"" + fila.nombre.trim() + "\";";
		//Contract Type
		sLinea += "\"\";";
		//Company ID
		sLinea += "\"\";";
		//External ID
		sLinea += "\"\";";
		
		sLinea += "\r\n";
		
		try {
			out.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
	}
	
	void ConvertFile(String ArchivoOrigen, String OrigenEncoding, String ArchivoDestino, String DestinoEncoding) {

		try {
			BufferedReader br = new BufferedReader(new InputStreamReader( new FileInputStream(ArchivoOrigen), OrigenEncoding));
			String line;

			Writer out = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(ArchivoDestino), DestinoEncoding));
			
		    while ((line = br.readLine()) != null) {
		        out.write(line);
		        out.write("\n");
		    }

		    br.close();
		    out.close();
		}catch(Exception 	e) {
			e.printStackTrace();
		}		

	}
	
}
