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
import java.nio.file.FileSystem;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

public class ConvenioSRV {
	private static Writer outConve=null;
	private static String sPathGenera;
	private static String sPathCopia;
	private static String sArchConve;
	private static int iTipoCorrida;

	public Boolean ProcesaConve(int iTipo, String sOS) {
		iTipoCorrida=iTipo;
		
		//Abre Archivos
		if(!AbreArchivos(sOS)) {
			System.out.println("No se pudieron abrir los archivos. Proceso Abortado");
			System.exit(1);
		}
		
		ConvenioDAO miDao = new ConvenioDAO();
		
		//proceso ppal ----
		if(!miDao.procesaConve(iTipo)) {
			System.out.println("Fallo el DAO");
			return false;
		}
		
		//Cierra Archivos
		CierraArchivos();
	
		//Copiar Archivos
		
		if(!MoverArchivo(sOS)) {
			System.out.println("No se pudo mover los archivos.");
		}

		return true;
	}

	public Boolean InformaConve(ConvenioDTO reg) {
		String sLinea="";
		
		
	   /* External Id */
		sLinea=String.format("\"%d%dAGRARG\";", reg.numero_cliente, reg.corr_convenio);

	   /* Tipo */
		sLinea+= "\"\";";

	   /* Opción de Convenio */
		sLinea+=String.format("\"%s\";", reg.opcion_convenio);

	   /* Estado */
		sLinea+=String.format("\"%s\";", reg.estado);

	   /* Fecha inicio */
		sLinea+=String.format("\"%sT00:00:00.000Z\";", reg.fecha_creacion);
	   
	   /* Fecha fin */
		if(reg.fecha_termino != null) {
			sLinea+=String.format("\"%sT00:00:00.000Z\";", reg.fecha_termino);
		}else {
			sLinea+= "\"\";";
		}
		
	   /* Deuda inicial */
		sLinea+=String.format("\"%.02f\";", reg.deuda_origen);

	   /* Pie */
		sLinea+=String.format("\"%.02f\";", reg.valor_cuota_ini);

	   /* Deuda pendiente */
		sLinea+=String.format("\"%.02f\";", reg.deuda_convenida);
   
	   /* Valor cuota */
		sLinea+=String.format("\"%.02f\";", reg.valor_cuota);

	   /* Valor última cuota */
		sLinea+=String.format("\"%.02f\";", reg.valor_cuota);

	   /* Total de cuotas */
		sLinea+=String.format("\"%d\";", reg.numero_tot_cuotas);

	   /* Cuota actual */
		sLinea+=String.format("\"%d\";", reg.numero_ult_cuota);

	   /* Tasa */
		sLinea+=String.format("\"%.02f\";", reg.intereses);

	   /* Contacto */
		sLinea+=String.format("\"%dARG\";", reg.numero_cliente);

	   /* Usuario creador */
		sLinea+=String.format("\"%s\";", reg.usuario_creacion);

	   /* Usuario término */
		if(reg.usuario_termino != null) {
			sLinea+=String.format("\"%s\";", reg.usuario_termino);
		}else {
			sLinea+= "\"\";";
		}
			

	   /* Total intereses */
		sLinea+= "\"\";";
	   /* Impuesto interés */
		sLinea+= "\"\";";
	   /* Descripcion seguro indexado */
		sLinea+= "\"\";";
	   /* Compañía de seguro */
		sLinea+= "\"\";";
	   /* Fecha inicio de seguro */
		sLinea+= "\"\";";
	   /* Fecha término del seguro */
		sLinea+= "\"\";";
	   /* Valor prima del seguro */
		sLinea+= "\"\";";
	   /* Número de cuotas */
		sLinea+=String.format("\"%d\";", reg.numero_tot_cuotas);

	   /* Estado seguro */
		sLinea+= "\"\";";
	   /* Fecha de baja */
		sLinea+= "\"\";";
	   /* Motivo de baja */
		sLinea+= "\"\";";
	   /* Suministro */
		sLinea+=String.format("\"%dAR\";", reg.numero_cliente);

	   /* Cuenta */
		sLinea+=String.format("\"%dARG\";", reg.numero_cliente);

	   /* Company */
		sLinea+= "\"9\";";

		sLinea += "\r\n";
		
		try {
			outConve.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		   
		
		return true;
	}
	
	private Boolean AbreArchivos( String sOS) {
		String sLinea="";
		ConvenioDAO miDao = new ConvenioDAO();
		String sClave = "";
		String sArchivoConve="";
		String sFilePathConve="";
		
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
		
		sArchivoConve= String.format("enel_care_agreement_t1_%s.csv", sFechaFMT);
		sFilePathConve=sPathGenera.trim() + sArchivoConve.trim();
		
		sArchConve=sArchivoConve;

		try {
			outConve = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathConve), "UTF-8"));
			sLinea = getTitulos();
			try {
				outConve.write(sLinea);
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
			outConve.close();
		}catch(Exception 	e) {
			e.printStackTrace();
		}
		
	}

	Boolean MoverArchivo(String sOs) {
		
		String sOriCnr = sPathGenera.trim() + sArchConve.trim();
		String sDestiCnr = sPathCopia.trim() + sArchConve.trim();

        Path pOriCnr = FileSystems.getDefault().getPath(sOriCnr);
        Path pDestiCnr = FileSystems.getDefault().getPath(sDestiCnr);
		
		try {
			Files.move(pOriCnr, pDestiCnr, StandardCopyOption.REPLACE_EXISTING);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
	String getTitulos() {
		String sLinea="";
		
		sLinea = "\"External Id\";"+
			"\"Tipo\";"+
			"\"Opción de Convenio\";"+
			"\"Estado\";"+
			"\"Fecha inicio\";"+
			"\"Fecha fin\";"+
			"\"Deuda inicial\";"+
			"\"Pie\";"+
			"\"Deuda pendiente\";"+
			"\"Valor cuota\";"+
			"\"Valor última cuota\";"+
			"\"Total de cuotas\";"+
			"\"Cuota actual\";"+
			"\"Tasa\";"+
			"\"Contacto\";"+
			"\"Usuario creador\";"+
			"\"Usuario término\";"+
			"\"Total intereses\";"+
			"\"Impuesto interés\";"+
			"\"Descripcion seguro indexado\";"+
			"\"Compañía de seguro\";"+
			"\"Fecha inicio de seguro\";"+
			"\"Fecha término del seguro\";"+
			"\"Valor prima del seguro\";"+
			"\"Número de cuotas\";"+
			"\"Estado seguro\";"+
			"\"Fecha de baja\";"+
			"\"Motivo de baja\";"+
			"\"Suministro\";"+
			"\"Cuenta\";"+
			"\"Company\""+
			"\r\n";
		
		
		return sLinea;
	}
}
