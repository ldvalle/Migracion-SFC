package servicios;

import dao.MeasuresDAO;
import entidades.ClienteDTO;
import entidades.MeasuresDTO;
import java.util.Collection;
import java.util.Vector;
import java.util.Date;
import java.text.SimpleDateFormat;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;


public class MeasuresSRV {

	private static String Plataforma;
	private static Writer outLectu =null;
	private static Writer outConsu =null;
	private static String sPathGenera;
	private static String sPathCopia;
	private static String sArchLectu;
	private static String sArchConsu;
	private static int iTipoFiles;
	
	public Boolean ProcesaMeasure(int iEstadoCliente, int iModoExtraccion, int iTipoArchivos, String sOS) {
		iTipoFiles=iTipoArchivos;
		
		//Abre Archivos
		if(!AbreArchivos(iTipoArchivos, sOS)) {
			System.out.println("No se pudieron abrir los archivos. Proceso Abortado");
			System.exit(1);
		}
		
		long lNroCliente=0;
		MeasuresDAO miDao = new MeasuresDAO();
		
		Plataforma=sOS;

		if(!miDao.ProcesaMeasures(iEstadoCliente, iModoExtraccion)){
			System.out.println("Fallo el DAO");
			return false;
		}
	
		//Cierra Archivos
		CierraArchivos();
	
		//Copiar Archivos
		if(!MoverArchivo()) {
			System.out.println("No se pudo mover los archivos.");
		}
		
		return true;
	}
	
	public Boolean ProcesaCliente(long lNroCliente) {
		MeasuresDAO miDao = new MeasuresDAO();
		Collection<MeasuresDTO>lstLectuActivas=null;
		MeasuresDTO regReactiva=null;
		
		lstLectuActivas=miDao.getLecturas(lNroCliente);

		for(MeasuresDTO miRegA : lstLectuActivas){
			if(miRegA.tipo_medidor==null) {
				miRegA.tipo_medidor="A";
			}
			
			switch(iTipoFiles) {
			case 0://Lecturas y Consumos
				GeneraPlanoLectura(miRegA, "A");
				GeneraPlanoConsumo(miRegA, "A");
				if(miRegA.tipo_medidor.equals("R")) {
					//Cargar Reactiva
					regReactiva = miDao.getHislecReac(miRegA.numero_cliente, miRegA.corr_facturacion, miRegA.tipo_lectura, miRegA.indica_refact);
					if(regReactiva != null) {
						miRegA.lectura_facturac=regReactiva.lectura_facturac;
						miRegA.lectura_terreno=regReactiva.lectura_terreno;
						miRegA.consumo=regReactiva.consumo;
						GeneraPlanoLectura(miRegA, "R");
						GeneraPlanoConsumo(miRegA, "R");
					}
				}
				break;
			case 1://Lecturas
				GeneraPlanoLectura(miRegA, "A");
				if(miRegA.tipo_medidor.equals("R")) {
					//Cargar Reactiva
					regReactiva = miDao.getHislecReac(miRegA.numero_cliente, miRegA.corr_facturacion, miRegA.tipo_lectura, miRegA.indica_refact);
					if(regReactiva != null) {
						miRegA.lectura_facturac=regReactiva.lectura_facturac;
						miRegA.lectura_terreno=regReactiva.lectura_terreno;
						miRegA.consumo=regReactiva.consumo;
						GeneraPlanoLectura(miRegA, "R");
					}
				}
				break;
			case 2://Consumos
				GeneraPlanoConsumo(miRegA, "A");
				if(miRegA.tipo_medidor.equals("R")) {
					//Cargar Reactiva
					regReactiva = miDao.getHislecReac(miRegA.numero_cliente, miRegA.corr_facturacion, miRegA.tipo_lectura, miRegA.indica_refact);
					if(regReactiva != null) {
						miRegA.lectura_facturac=regReactiva.lectura_facturac;
						miRegA.lectura_terreno=regReactiva.lectura_terreno;
						miRegA.consumo=regReactiva.consumo;
						GeneraPlanoConsumo(miRegA, "R");
					}
				}
				break;
				
			}
			
		}
		
		
		return true;
	}
	
	private Boolean AbreArchivos(int iTipoArchivos, String sOS) {
		String sLinea="";
		MeasuresDAO miDao = new MeasuresDAO();
		String sClave = "";
		String sArchivoLecturas="";
		String sFilePathLecturas="";
		String sArchivoConsumos="";
		String sFilePathConsumos="";
		
		Date dFechaHoy = new Date();
		
		SimpleDateFormat fechaF = new SimpleDateFormat("yyyyMMdd");
		String sFechaFMT=fechaF.format(dFechaHoy);

		
		sClave = "SALESF";
		sPathGenera=miDao.getPathFile(sClave);
		sClave = "SALEFC";
		sPathCopia=miDao.getPathFile(sClave);
		
		if(sOS.equals("DOS")){
			sPathGenera="C:\\Users\\ar17031095.ENELINT\\Documents\\data_in\\";
			sPathCopia="C:\\Users\\ar17031095.ENELINT\\Documents\\data_out\\";
		}
		
		sArchivoLecturas= String.format("enel_care_measures_counters_t1_%s.csv", sFechaFMT);
		sFilePathLecturas=sPathGenera.trim() + sArchivoLecturas.trim();
		
		sArchivoConsumos= String.format("enel_care_consumption_t1_%s.csv", sFechaFMT);
		sFilePathConsumos=sPathGenera.trim() + sArchivoConsumos.trim();
		sArchLectu=sArchivoLecturas;
		sArchConsu=sArchivoConsumos;
		
		try {
			switch(iTipoArchivos) {
			case 0:	//Lecturas y Consumos
				outLectu = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathLecturas), "UTF-8"));
				sLinea=getTitulos("LECTU");
				try {
					outLectu.write(sLinea);
				}catch(Exception e) {
					e.printStackTrace();
				}
				
				outConsu = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathConsumos), "UTF-8"));
				sLinea=getTitulos("CONSU");
				try {
					outConsu.write(sLinea);
				}catch(Exception e) {
					e.printStackTrace();
				}
				
				break;
			case 1://Lecturas
				outLectu = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathLecturas), "UTF-8"));
				sLinea=getTitulos("LECTU");
				try {
					outLectu.write(sLinea);
				}catch(Exception e) {
					e.printStackTrace();
				}
				
				break;
			case 2://Consumos
				outConsu = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathConsumos), "UTF-8"));
				sLinea=getTitulos("CONSU");
				try {
					outConsu.write(sLinea);
				}catch(Exception e) {
					e.printStackTrace();
				}
				
				break;
			}

		}catch(Exception 	e) {
			e.printStackTrace();
		}
		
		return true;
	}

	void CierraArchivos() {
		try {
			outLectu.close();
			outConsu.close();
		}catch(Exception 	e) {
			e.printStackTrace();
		}
		
	}
	
	String getTitulos(String sTipo) {
		String sTitulo="";
		
		if(sTipo.equals("LECTU")) {
			sTitulo="\"Suministro\";\"Fecha Evento\";\"Evento Medicion\";\"Tipo de Medida\";\"Numero Medidor\";\"Constante\";\"Consumo\";\"Lectura\";\"Lectura Terreno\";\"Clave Medicion\";\"Irregularidad de Lectura\";\"Caso de Atencion\";\"Factura\";\"External ID\";\"Fecha Proxima Lectura\";\"CreatedByClient\";\r\n";
		}else {
			sTitulo="\"Suministro\";\"Factura\";\"Tipo de consumo\";\"Consumo facturado\";\"Clave de consumo\";\"Tipo de medida\";\"External Id\";\"Fecha del evento\";\"Número Medidor\";\"Coseno Phi\";\r\n";
		}
		
		return sTitulo;
	}
	
	void GeneraPlanoLectura(MeasuresDTO reg, String tipoMedidor) {
		String sLinea="";
		
	   // Suministro
		sLinea = String.format("\"%dAR\";",reg.numero_cliente);
	   
	   // Fecha Evento
		sLinea += String.format("\"%s\";", reg.fecha_lectura);
	   
	   // Evento Medicion (vacio)
		sLinea +="\"\";";
	   
	   // Tipo de Medida
	   if(tipoMedidor.equals("A")){
		   sLinea+="\"ACTI\";";
	   }else{
		   sLinea+="\"REAC\";";
	   }
	   
	   // ID Medidor
	   sLinea += String.format("\"%d%s%s\";", reg.numero_medidor, reg.marca_medidor, reg.modelo_medidor);
	   
	   // Constante
	   sLinea += String.format("\"%.05f\";", reg.constante);
	   
	   // Consumo
	   sLinea += String.format("\"%d\";", reg.consumo);

	   // Lectura
	   sLinea += String.format("\"%.0f\";", reg.lectura_facturac);

	   // Lectura Terreno
	   if(reg.lectura_terreno > 0.01) {
		   sLinea+= String.format("\"%.0f\";", reg.lectura_terreno);
	   }else {
		   sLinea+= String.format("\"%.0f\";", reg.lectura_facturac);
	   }
	   
	   // clave Medicion
	   sLinea += "\"NORMAL READING\";";

	   // Irregularidad lectura (vacio)
	   sLinea+="\"\";";

	   // caso de antencion (vacio) 
	   sLinea+="\"\";";

	   // Factura
	   sLinea+=String.format("\"%s\";", reg.id_factura);
	   
	   // External ID
	   sLinea += String.format("\"%d%dAR\";", reg.numero_cliente, reg.corr_facturacion);
	   
	   // Fecha Prox.Lectura (vacio)
	   sLinea+="\"\";";
	   
	   // CreatedByClient
	   sLinea+="\"FALSE\";";

	   sLinea += "\r\n";
		
		try {
			outLectu.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}

		
	}
	
	void GeneraPlanoConsumo(MeasuresDTO reg, String tipoMedidor) {
		String sLinea="";

	   // Suministro
		sLinea = String.format("\"%dAR\";", reg.numero_cliente);
	   
	   // Factura
		sLinea += String.format("\"%sAR\";", reg.id_factura);
	
	   // Tipo de Consumo
		if(tipoMedidor.equals("A")) {
			sLinea+= "\"ACTI\";";
		}else {
			sLinea+= "\"REAC\";";
		}
	
	   // Consumo Facturado
		sLinea += String.format("\"%d\";", reg.consumo);
	
	   // Clave de consumo (vacio)
		sLinea+= "\"\";";
	
	   // Tipo de Medida
		if(tipoMedidor.equals("A")) {
			sLinea+= "\"ACTI\";";
		}else {
			sLinea+= "\"REAC\";";
		}
	   
	   // External ID
		sLinea+= String.format("\"%d%dAR\";", reg.numero_cliente, reg.corr_facturacion);
	   
	   // Fecha Facturacion
		sLinea+= String.format("\"%s\"", reg.fecha_facturacion);

		// Nro + marca + modelo de medidor
		sLinea += String.format("\"%d%s%s\";", reg.numero_medidor, reg.marca_medidor, reg.modelo_medidor);
		
		// Coseno Phi
		sLinea+= String.format("\"%.02f\";", reg.coseno_phi);
		
		sLinea += "\r\n";		
		
		try {
			outConsu.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
	}
	
	Boolean MoverArchivo() {
		String sOriLectu = sPathGenera.trim() + sArchLectu.trim();
		String sDestiLectu = sPathCopia.trim() + sArchLectu.trim();
		
        Path pOriLectu = FileSystems.getDefault().getPath(sOriLectu);
        Path pDestiLectu = FileSystems.getDefault().getPath(sDestiLectu);
        
		String sOriConsu = sPathGenera.trim() + sArchConsu.trim();
		String sDestiConsu = sPathCopia.trim() + sArchConsu.trim();
		
        Path pOriConsu = FileSystems.getDefault().getPath(sOriConsu);
        Path pDestiConsu = FileSystems.getDefault().getPath(sDestiConsu);
        
		try {
			switch(iTipoFiles) {
			case 0:
				Files.move(pOriLectu, pDestiLectu, StandardCopyOption.REPLACE_EXISTING);
				Files.move(pOriConsu, pDestiConsu, StandardCopyOption.REPLACE_EXISTING);
				break;
			case 1:
				Files.move(pOriLectu, pDestiLectu, StandardCopyOption.REPLACE_EXISTING);
				break;
			case 2:
				Files.move(pOriConsu, pDestiConsu, StandardCopyOption.REPLACE_EXISTING);
				break;
			}
			
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
	
}
