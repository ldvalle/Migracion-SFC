package servicios;

import java.util.*;
import entidades.*;
import dao.*;

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

public class CnrSRV {
	private static Writer outCnr=null;
	private static String sPathGenera;
	private static String sPathCopia;
	private static String sArchCnr;
	private static int iTipoCorrida;


	public Boolean ProcesaCnr(int iTipo, String sOS) {
		iTipoCorrida=iTipo;
		
		//Abre Archivos
		if(!AbreArchivos(sOS)) {
			System.out.println("No se pudieron abrir los archivos. Proceso Abortado");
			System.exit(1);
		}
		
		cnrDAO miDao = new cnrDAO();

		
		//proceso ppal ----
		if(!miDao.procesaCNR(iTipo)) {
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

	private Boolean AbreArchivos( String sOS) {
		String sLinea="";
		cnrDAO miDao = new cnrDAO();
		String sClave = "";
		String sArchivoCnr="";
		String sFilePathCnr="";
		
		Date dFechaHoy = new Date();
		
		SimpleDateFormat fechaF = new SimpleDateFormat("yyyyMMdd");
		String sFechaFMT=fechaF.format(dFechaHoy);

		
		sClave = "SALESF";
		sPathGenera=miDao.getRuta(sClave);
		sClave = "SALEFC";
		sPathCopia=miDao.getRuta(sClave);
		
		if(sOS.equals("DOS")){
			sPathGenera="C:\\Users\\ar17031095.ENELINT\\Documents\\data_in\\";
			sPathCopia="C:\\Users\\ar17031095.ENELINT\\Documents\\data_out\\";
		}
		
		sArchivoCnr= String.format("enel_care_marketdicipline_t1_%s.csv", sFechaFMT);
		sFilePathCnr=sPathGenera.trim() + sArchivoCnr.trim();
		
		sArchCnr=sArchivoCnr;

		try {
			outCnr = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathCnr), "UTF-8"));
			sLinea = "\"Suministro\";\"Nro. Expediente\";\"Fecha creación expediente\";\"Condicion del expediente\";\"Año del expediente\";\"Fecha Inicio\";\"Fecha Fin\";\"Fecha inicio energía\";\"Fecha fin energía\";\"Estado\";\"Monto Expediente\";\"Cantidad de cuotas\";\"Número de medidor\";\"External Id\";";
			
			try {
				outCnr.write(sLinea);
			}catch(Exception e) {
				e.printStackTrace();
			}
		}catch(Exception e) {
			e.printStackTrace();
		}
		return true;
	}

	void CierraArchivos() {
		try {
			outCnr.close();
		}catch(Exception 	e) {
			e.printStackTrace();
		}
		
	}

	Boolean MoverArchivo() {
		String sOriCnr = sPathGenera.trim() + sArchCnr.trim();
		String sDestiCnr = sPathCopia.trim() + sArchCnr.trim();
		
        Path pOriCnr = FileSystems.getDefault().getPath(sOriCnr);
        Path pDestiCnr = FileSystems.getDefault().getPath(sDestiCnr);
        
		try {
			Files.move(pOriCnr, pDestiCnr, StandardCopyOption.REPLACE_EXISTING);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
	public Boolean InformaCnr(CnrDTO cnr) {
		String sLinea = "";
		
	   /* Suministro */
		sLinea = String.format("\"%dAR\";", cnr.numero_cliente);
	   
	   /* Nro. Expediente */
		sLinea += String.format("\"%d\";", cnr.nro_expediente);
	   
	   /* Fecha creación expediente */
		sLinea += String.format("\"%d\";", cnr.nro_expediente);
	   
	   /* Condicion del expediente */
		sLinea += String.format("\"%s\";", cnr.descripcion);
	   
	   /* Año del expediente */
		sLinea += String.format("\"%d\";", cnr.ano_expediente);
	   
	   /* Fecha Inicio */
		sLinea += String.format("\"%s\";", cnr.fecha_inicio);
	   
	   /* Fecha Fin */
		if(cnr.fecha_finalizacion != null) {
			sLinea += String.format("\"%s\";", cnr.fecha_finalizacion.trim());
		}else {
			sLinea += "\"\";";
		}
	   
	   /* Fecha inicio energía */
		if(cnr.sFechaDesdePeriCalcu != null) {
			sLinea += String.format("\"%s\";", cnr.sFechaDesdePeriCalcu.trim());
		}else {
			sLinea += "\"\";";
		}
	   
	   /* Fecha fin energía */
		if(cnr.sFechaHastaPeriCalcu != null) {
			sLinea += String.format("\"%s\";", cnr.sFechaHastaPeriCalcu.trim());
		}else {
			sLinea += "\"\";";
		}
	   
	   /* Estado */
		sLinea += String.format("\"%s\";", cnr.cod_estado);
	   
	   /* Monto Expediente */
		if(cnr.total_calculo != null) {
			sLinea += String.format("\"%.02f\";", cnr.total_calculo);
		}else {
			sLinea += "\"\";";
		}
	   
	   /* Cantidad de cuotas */
		sLinea += "\"\";";
	   
	   /* Número de medidor */
	    sLinea += String.format("\"%d%d%s%sDEVARG\";",cnr.numero_cliente, cnr.numero_medidor, cnr.marca_medidor, cnr.modelo_medidor);
	   
	   /* External Id */
	    sLinea += String.format("\"%d%s%d\";", cnr.ano_expediente, cnr.sucursal, cnr.nro_expediente);

		sLinea += "\r\n";
			
		try {
			outCnr.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		   
		return true;
	}
}
