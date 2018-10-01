package servicios;

import java.util.*;
import entidades.*;
import dao.*;

import java.util.Collection;
import java.util.Vector;
import java.util.Date;
import java.sql.SQLException;
import java.text.SimpleDateFormat;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

import org.apache.commons.lang3.StringUtils;

public class ExtragenSRV {
	private static Writer outFileAddress=null;
	private static String sArchivoSalidaAddress;
	private static Writer outFileAsset=null;
	private static String sArchivoSalidaAsset;
	private static Writer outFileContacto=null;
	private static String sArchivoSalidaContacto;
	private static Writer outFileCuenta=null;
	private static String sArchivoSalidaCuenta;
	private static Writer outFilePoint=null;
	private static String sArchivoSalidaPoint;
	private static Writer outFileService=null;
	private static String sArchivoSalidaService;
	
	private static String sPathGenera;
	private static String sPathCopia;
	
	private static int iTipoCorrida;
	private static int iEstadoClientes;

	public Boolean ProcesoGral(int iTipo, int iEstado, String sOS) throws SQLException {
		iTipoCorrida=iTipo;
		iEstadoClientes=iEstado;
		
		//Abre Archivos
		if(!AbreArchivos(sOS)) {
			System.out.println("No se pudieron abrir los archivos. Proceso Abortado");
			System.exit(1);
		}
		
		ExtragenDAO miDao = new ExtragenDAO();
		
		//proceso ppal
		if(!miDao.ProcesoPpal(iTipoCorrida, iEstado)) {
			System.out.println("Fallo el DAO para Datos Generales");
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
	/*
	public Boolean ProcesaCliente(long lNroCliente) {
		ExtragenDAO miDao = new ExtragenDAO();
		ExtragenDTO miClie = null;

		miClie = miDao.getClienteGral(lNroCliente);

		return true;
	}
	*/
	private Boolean AbreArchivos( String sOS) throws SQLException {
		String sLinea="";
		ExtragenDAO miDao = new ExtragenDAO();
		String sClave = "";
		String sArchivoAddress="";
		String sFilePathAddress="";
		String sArchivoAsset="";
		String sFilePathAsset="";
		String sArchivoContacto="";
		String sFilePathContacto="";
		String sArchivoCuenta="";
		String sFilePathCuenta="";
		String sArchivoPoint="";
		String sFilePathPoint="";
		String sArchivoService="";
		String sFilePathService="";

		
		Date dFechaHoy = new Date();
		
		SimpleDateFormat fechaF = new SimpleDateFormat("yyyyMMdd");
		String sFechaFMT=fechaF.format(dFechaHoy);

		if(sOS.equals("DOS")){
			sPathGenera="C:\\Users\\ar17031095.ENELINT\\Documents\\data_in\\";
			sPathCopia="C:\\Users\\ar17031095.ENELINT\\Documents\\data_out\\";
		} else {
			sClave = "SALESF";
			sPathGenera=miDao.getRuta(sClave);
			sClave = "SALEFC";
			sPathCopia=miDao.getRuta(sClave);
		}

		//-- Archivo de Address
		sArchivoAddress= String.format("enel_care_address_t1_%s.csv", sFechaFMT);
		sFilePathAddress=sPathGenera.trim() + sArchivoAddress.trim();
		sArchivoSalidaAddress=sArchivoAddress;
		try {
			outFileAddress = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathAddress), "UTF-8"));
			sLinea = getTitulos(1);
			try {
				outFileAddress.write(sLinea);
			}catch(Exception e) {
				e.printStackTrace();
			}
		}catch(Exception e) {
			e.printStackTrace();
		}
		//-- Archivo de Asset
		sArchivoAsset= String.format("enel_care_asset_t1_%s.csv", sFechaFMT);
		sFilePathAsset=sPathGenera.trim() + sArchivoAsset.trim();
		sArchivoSalidaAsset=sArchivoAsset;
		try {
			outFileAsset = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathAsset), "UTF-8"));
			sLinea = getTitulos(2);
			try {
				outFileAsset.write(sLinea);
			}catch(Exception e) {
				e.printStackTrace();
			}
		}catch(Exception e) {
			e.printStackTrace();
		}
		//-- Archivo de Contacto
		sArchivoContacto= String.format("enel_care_contact_t1_%s.csv", sFechaFMT);
		sFilePathContacto=sPathGenera.trim() + sArchivoContacto.trim();
		sArchivoSalidaContacto=sArchivoContacto;
		try {
			outFileContacto = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathContacto), "UTF-8"));
			sLinea = getTitulos(3);
			try {
				outFileContacto.write(sLinea);
			}catch(Exception e) {
				e.printStackTrace();
			}
		}catch(Exception e) {
			e.printStackTrace();
		}
		//-- Archivo de Cuenta
		sArchivoCuenta= String.format("enel_care_account_t1_%s.csv", sFechaFMT);
		sFilePathCuenta=sPathGenera.trim() + sArchivoCuenta.trim();
		sArchivoSalidaCuenta=sArchivoCuenta;
		try {
			outFileCuenta = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathCuenta), "UTF-8"));
			sLinea = getTitulos(4);
			try {
				outFileCuenta.write(sLinea);
			}catch(Exception e) {
				e.printStackTrace();
			}
		}catch(Exception e) {
			e.printStackTrace();
		}
		//-- Archivo de Point
		sArchivoPoint= String.format("enel_care_pointofdelivery_t1_%s.csv", sFechaFMT);
		sFilePathPoint=sPathGenera.trim() + sArchivoPoint.trim();
		sArchivoSalidaPoint=sArchivoPoint;
		try {
			outFilePoint = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathPoint), "UTF-8"));
			sLinea = getTitulos(5);
			try {
				outFilePoint.write(sLinea);
			}catch(Exception e) {
				e.printStackTrace();
			}
		}catch(Exception e) {
			e.printStackTrace();
		}
		//-- Archivo de Service
		sArchivoService= String.format("enel_care_serviceproduct_t1_%s.csv", sFechaFMT);
		sFilePathService=sPathGenera.trim() + sArchivoService.trim();
		sArchivoSalidaService=sArchivoService;
		try {
			outFileService = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(sFilePathService), "UTF-8"));
			sLinea = getTitulos(6);
			try {
				outFileService.write(sLinea);
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
			outFileAddress.close();
			outFileAsset.close();
			outFileContacto.close();
			outFileCuenta.close();
			outFilePoint.close();
			outFileService.close();
		}catch(Exception 	e) {
			e.printStackTrace();
		}
		
	}

	Boolean MoverArchivo() {
		String sOriAddress = sPathGenera.trim() + sArchivoSalidaAddress.trim();
		String sDestiAddress = sPathCopia.trim() + sArchivoSalidaAddress.trim();
        Path pOriAddress = FileSystems.getDefault().getPath(sOriAddress);
        Path pDestiAddress = FileSystems.getDefault().getPath(sDestiAddress);

		String sOriAsset = sPathGenera.trim() + sArchivoSalidaAsset.trim();
		String sDestiAsset = sPathCopia.trim() + sArchivoSalidaAsset.trim();
        Path pOriAsset = FileSystems.getDefault().getPath(sOriAsset);
        Path pDestiAsset = FileSystems.getDefault().getPath(sDestiAsset);

		String sOriContacto = sPathGenera.trim() + sArchivoSalidaContacto.trim();
		String sDestiContacto = sPathCopia.trim() + sArchivoSalidaContacto.trim();
        Path pOriContacto = FileSystems.getDefault().getPath(sOriContacto);
        Path pDestiContacto = FileSystems.getDefault().getPath(sDestiContacto);

		String sOriCuenta = sPathGenera.trim() + sArchivoSalidaCuenta.trim();
		String sDestiCuenta = sPathCopia.trim() + sArchivoSalidaCuenta.trim();
        Path pOriCuenta = FileSystems.getDefault().getPath(sOriCuenta);
        Path pDestiCuenta = FileSystems.getDefault().getPath(sDestiCuenta);

		String sOriPoint = sPathGenera.trim() + sArchivoSalidaPoint.trim();
		String sDestiPoint = sPathCopia.trim() + sArchivoSalidaPoint.trim();
        Path pOriPoint = FileSystems.getDefault().getPath(sOriPoint);
        Path pDestiPoint = FileSystems.getDefault().getPath(sDestiPoint);

		String sOriService = sPathGenera.trim() + sArchivoSalidaService.trim();
		String sDestiService = sPathCopia.trim() + sArchivoSalidaService.trim();
        Path pOriService = FileSystems.getDefault().getPath(sOriService);
        Path pDestiService = FileSystems.getDefault().getPath(sDestiService);
        
		try {
			Files.move(pOriAddress, pDestiAddress, StandardCopyOption.REPLACE_EXISTING);
			Files.move(pOriAsset, pDestiAsset, StandardCopyOption.REPLACE_EXISTING);
			Files.move(pOriContacto, pDestiContacto, StandardCopyOption.REPLACE_EXISTING);
			Files.move(pOriCuenta, pDestiCuenta, StandardCopyOption.REPLACE_EXISTING);
			Files.move(pOriPoint, pDestiPoint, StandardCopyOption.REPLACE_EXISTING);
			Files.move(pOriService, pDestiService, StandardCopyOption.REPLACE_EXISTING);
			
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
	
	String getTitulos(int iFile) {
		String sLinea="";
		
		switch(iFile) {
		case 1: //Address
			sLinea = "\"Divisa\";" + 
					"\"Esquina\";" + 
					"\"Numero\";" + 
					"\"Referencia\";" + 
					"\"Código Postal\";" + 
					"\"Número\";" +
					"\"Identificador Calle\";" + 
					"\"Departamento\";" + 
					"\"Calle\";" +
					"\"Tipo de Numeracion\";" + 
					"\"Dirección Concatenada\";" + 
					"\"Sector\";" + 
					"\"Coordenada X\";" + 
					"\"Coordenada Y\";" + 
					"\"Nombre de Agrupacion\"" +
					"\"Tipo de Agrupacion\";" +
					"\"Tipo de Interior\";" +
					"\"Dirección Larga\";" +
					"\"Lote/Manzana\";" +
					"\"Tipo de Sector\";" +
					"\"CompanyID\";" +
					"\"Interseccion 1\";" +
					"\"Interseccion 2\";" +
					"\"Piso\";" +
					"\"Departamento\";" +
					"\"Edificio\";";
			break;
		case 2: //Account
			sLinea = "\"Identificador Activo\";" + 
					"\"Nombre del Activo\";" + 
					"\"Cuenta\";" + 
					"\"Contacto\";" + 
					"\"Suministro\";" + 
					"\"Descripcion\";" +
					"\"Producto\";" + 
					"\"Estado\";" + 
					"\"Contacto Principal\";" +
					"\"Contrato\";" + 
					"\"Estado Contratacion\";"; 
			break;
		case 3: //Contact
			sLinea = "\"Identificador de Cuenta\";" + 
					"\"Nombre\";" + 
					"\"Apellido\";" + 
					"\"Saludo\";" + 
					"\"Nombre de la Cuenta\";" + 
					"\"Estado Civil\";" +
					"\"Género\";" + 
					"\"Tipo de Identificacion\";" + 
					"\"Numero de Documento\";" +
					"\"Fase del ciclo de vida del cliente\";" + 
					"\"Estrato\";" + 
					"\"Nivel educacional\";" + 
					"\"Autoriza uso de informacion personal\";" + 
					"\"No llamar\";" + 
					"\"No recibir correos electrónicos\"" +
					"\"Profesion\";" +
					"\"Ocupacion\";" +
					"\"Fecha nacimiento\";" +
					"\"Canal preferente de contacto\";" +
					"\"Correo electronico\";" +
					"\"Correo electronico secundario\";" +
					"\"Telefono\";" +
					"\"Telefono secundario\";" +
					"\"Telefono movil\";" +
					"\"Moneda\";" +
					"\"Apellido paterno\";" +
					"\"Apellido materno\";" +
					"\"Tipo de acreditacion\";" +
					"\"Dirección del contacto\";" +
					"\"Nombre de usuario de Twitter\";" +
					"\"Recuento de seguidores de Twitter\";" +
					"\"Influencia\";" +
					"\"Tipo de influencia\";" +
					"\"Biografía de Twitter\";" +
					"\"Id.de usuario de Twitter\";" +
					"\"Nombre de usuario de Facebook\";" +
					"\"Id.de usuario de Facebook\";" +
					"\"Id.de empresa\";";
			break;
		case 4: //Cuenta
			sLinea ="\"Identificador cuenta\";" +
					"\"Nombre de la cuenta\";" +
					"\"Tipo de identidad\";" +
					"\"Número de identidad\";" +
					"\"Email principal\";" +
					"\"Email secundario\";" +
					"\"Telefono principal\";" +
					"\"Telefono secundario\";" +
					"\"Telefono adicional\";" +
					"\"Divisa\";" +
					"\"Tipo de Registro\";" +
					"\"Fecha de nacimiento\";" +
					"\"Cuenta principal\";" +
					"\"Apellido materno\";" +
					"\"Apellido paterno\";" +
					"\"Dirección\";" +
					"\"Ejecutivo\";" +
					"\"Giro\";" +
					"\"Clase de Servicio\";" +
					"\"Id Empresa\";" +
					"\"Razon social de la empresa\";" +
					"\"Condicion Impositiva\";" +
					"\"Email Adicional\";" +
					"\"Tipo de Cuenta\";" +
					"\"Cuenta Cliente\";" +
					"\"Cuenta Padre\";" +
					"\"Clase de Cuenta\";" +
					"\"Tipo de Sociedad\";";
			
			break;
		case 5: //Point of delivery
			sLinea = "\"Identificador PoD\";" +
					"\"Numero PoD\";" +
					"\"Divisa\";" +
					"\"DV Número de suministro\";" +
					"\"Direccion\";" +
					"\"Estado del suministro\";" +
					"\"Pais\";" +
					"\"Comuna\";" +
					"\"Tipo de segmento\";" +
					"\"Medida de disciplina\";" +
					"\"Id empresa\";" +
					"\"Electrodependiente\";" +
					"\"Tarifa\";" +
					"\"Tipo de agrupacion\";" +
					"\"Full electric\";" +
					"\"Nombre boleta\";" +
					"\"Ruta\";" +
					"\"Direccion de reparto\";" +
					"\"Comuna de reparto\";" +
					"\"Numero de Transformador\";" +
					"\"Tipo de Transformador\";" +
					"\"Tipo de Conexión\";" +
					"\"Estrato socioeconómico\";" +
					"\"Subestacion Electrica Conexion\";" +
					"\"Tipo de medida\";" +
					"\"Número de alimentador\";" +
					"\"Tipo de lectura\";" +
					"\"Bloque\";" +
					"\"Horario de racionamiento\";" +
					"\"Estado de conexion\";" +
					"\"Fecha de corte\";" +
					"\"Código PRC\";" +
					"\"SED\";" +
					"\"SET\";" +
					"\"Llave\";" +
					"\"Potencia Instalada\";" +
					"\"Cliente singular\";" +
					"\"Clase de servicio\";" +
					"\"subclase de servicio\";" +
					"\"Ruta de lectura\";" +
					"\"Tipo de liquidación\";" +
					"\"Mercado\";" +
					"\"Carga aforada\";" +
					"\"Año de fabricacion\";" +
					"\"Cantidad de Personas\";" +
					"\"Numero de DCI\";" +
					"\"Ente Emisor DCI\";" +
					"\"Potencia Convenida\";" +
					"\"Fecha Desconexion\";";
			break;
		case 6: //Service Product
			sLinea = "\"Activo\";" +
					"\"Contacto\";" +
					"\"Cuenta\";" +
					"\"Pais\";" +
					"\"Compañia\";" +
					"\"ExternalID\";" +
					"\"Contacto Principal\";" +
					"\"Electrodependiente\";" +
					"\"Numero de DCI\";" +
					"\"Ente Emisor DCI\";";
			break;
		}
		
		sLinea += "\r\n";
		
		return sLinea;
	}
	
	public Boolean InformaExtragen(ExtragenDTO extragen) throws SQLException {
		
		if (!InformaAddress(extragen))
			return false;
		   
		if (!InformaCuentas(extragen))
			return false;
		  
		if (!InformaContactos(extragen))
			return false;
		
		if (!InformaPointerDelivery(extragen))
			return false;
					
		if (!GeneraServiceProduct(extragen))
			return false;
					
		if (!GeneraAsset(extragen))
			return false;
					
		return true;
	}
	
	private Boolean InformaAddress (ExtragenDTO extragen) throws SQLException {
		String sLinea = "";
		String sAux = "";
		String sAuxL = "";
		String sObs = "";

		sAux = String.format("%s %s ", extragen.nom_calle, extragen.nro_dir);
				
		if(extragen.piso_dir != null) {
			sAux += String.format("piso %s ", extragen.piso_dir.trim());
		}
		
		if(extragen.depto_dir != null)
			sAux += String.format("Dpto. %s", extragen.depto_dir.trim());	

		sAuxL = sAux;
	   
		if(extragen.comuna != null)
			sAuxL += String.format(" Loc. %s", extragen.nom_comuna.trim() );
	   
		if(extragen.partido != null)
			sAuxL += String.format(" Part. %s", extragen.nom_partido.trim() );
	      
		if(extragen.obs_dir!=null)
			sObs = extragen.obs_dir.trim();
	   
		if(extragen.entre_calle1 != null && extragen.entre_calle2 != null)
			if(sObs != null)
				sObs += String.format(" (Entre calle: %s y calle: %s)", extragen.entre_calle1.trim(), extragen.entre_calle2.trim());
			else
				sObs = String.format("(Entre calle: %s y calle: %s)", extragen.entre_calle1.trim(), extragen.entre_calle2.trim());
	      
		/* MONEDA */
		sLinea += String.format("\"ARS\";");
			
		/* ESQUINA (VACIO) */
		sLinea += String.format("\"\";");
		
		/* ALTURA */
		if(extragen.dp_nro_dir != null) {
			sLinea += String.format("\"%s\";", extragen.nro_dir.trim());
		}else {
			sLinea += String.format("\"\";");
		}

		/* OBSERVACIONES */
		if(sObs != null)
			sLinea += String.format("\"%s\";", sObs.trim());
		else
			sLinea += String.format("\"\";");	
		
		/* CP  */
		if (extragen.cod_postal != null)
			sLinea += String.format("\"%d\";", extragen.cod_postal);
		else
			sLinea += String.format("\"\";");
		
		/* ID */
		StringUtils.trim(extragen.tipo_reparto);

		if(extragen.tipo_reparto.trim().equals("POSTAL"))
			sLinea += String.format("\"%d-1ARG\";", extragen.numero_cliente);
		else
		   	sLinea += String.format("\"%d-2ARG\";", extragen.numero_cliente);
		
		/* ID-CALLE */
		if(extragen.cod_calle != null && !extragen.cod_calle.trim().equals("-1"))
			/*sLinea += String.format("%s\"%d-2\";", sLinea, extragen.numero_cliente);*/
			sLinea += String.format("\"A0000AARG\";");
		else
			if (ValidaCalle(extragen))
				sLinea += String.format("\"%s%sARG\";", extragen.cod_calle.trim(), extragen.comuna.trim());
			else
				sLinea += String.format("\"A0000AARG\";");

		/* DEPARTAMENTO  */
		StringUtils.trim(extragen.nom_barrio);
		StringUtils.trim(extragen.nom_comuna);
		if(extragen.nom_comuna != null)
			sLinea += String.format("\"%s\";", extragen.nom_comuna.trim());
		else 
			sLinea += String.format("\"\";");
		
	   
		/* CALLE (VACIO) */
		sLinea += String.format("\"\";");
		/* TIPO NUMERACION (VACIO) */
		sLinea += String.format("\"\";");
		
		/* DIRECCION */
		sLinea += String.format("\"%s\";", sAux);

		/* SECTOR (VACIO) */
		sLinea += String.format("\"\";");
		/* X (VACIO) */
		sLinea += String.format("\"\";");
		/* Y (VACIO) */
		sLinea += String.format("\"\";");
		/* NOMBRE AGRUPACION (VACIO) */
		sLinea += String.format("\"\";");
		/* TIPO AGRUPACION (VACIO) */
		sLinea += String.format("\"\";");
		/* TIPO INTERIOR (VACIO) */
		sLinea += String.format("\"\";");
		/* DIRECCION LARGA */
		sLinea += String.format("\"%s\";", sAuxL);

		/* LOTE (VACIO) */
		sLinea += String.format("\"\";");

		/* TIPO SECTOR (VACIO) */
		sLinea += String.format("\"\";");

		/* COMPANY ID */
		sLinea += String.format("\"9\";");
	   
		/* INTERSECCION1 */
		if(extragen.entre_calle1 != null)
			sLinea += String.format("\"%s\";", extragen.entre_calle1.trim());
		else
			sLinea += String.format("\"\";");
		
		/* INTERSECCION2 */
		if(extragen.entre_calle2 != null)
			sLinea += String.format("\"%s\";", extragen.entre_calle2.trim());
		else
			sLinea += String.format("\"\";");

		/* PISO */
		if(extragen.piso_dir != null)
			sLinea += String.format("\"%s\";", extragen.piso_dir.trim());
		else
			sLinea += String.format("\"\";");
	   
		/* DEPARTAMENTO */
		if(extragen.depto_dir != null)
			sLinea += String.format("\"%s\";", extragen.depto_dir.trim());
		else
			sLinea += String.format("\"\";");
	   
		/* EDIFICIO */
		sLinea += String.format("\"\";");
	   
		sLinea += "\r\n";
			
		try {
			outFileAddress.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}

		return true;
	}

	private Boolean ValidaCalle(ExtragenDTO reg) throws SQLException
	{
	   long lAltura;
	   
	   lAltura = Long.parseLong(reg.nro_dir);
	   
	   if(lAltura <= 0)
	      return false;  
	   	               
	   if(StringUtils.equals(reg.cod_calle, ""))
	      return false;

	   if(StringUtils.equals(reg.partido, ""))
	      return false;
	   	               
	   if(StringUtils.equals(reg.comuna, ""))
	      return false;
	   
	   ExtragenDAO miDao = new ExtragenDAO();
	   return miDao.getValCalle(reg.cod_calle, lAltura, reg.partido, reg.comuna);
	}

	private Boolean InformaCuentas (ExtragenDTO extragen) throws SQLException {
		String sLinea = "";

		/* ID */
		sLinea = String.format("\"%dARG\";", extragen.numero_cliente);
		
		/* NOMBRE */
		sLinea += String.format("\"%s\";", extragen.nombre.trim());
		
		/* Tipo y Nro.de Documento */
		if(extragen.es_empresa != null && extragen.es_empresa.trim().equals("S")) {
			if(extragen.rut !=null && extragen.rut.length()>0){
				/* TIPO DOCUMENTO */
				sLinea += String.format("\"CUIT\";");
				/* NRO DOCUMENTO */
				sLinea += String.format("\"%s\";", extragen.rut.trim());
			}else{
				/* TIPO DOCUMENTO */
				if(extragen.tip_doc !=null && !extragen.tip_doc.trim().equals("DEF"))
					sLinea += String.format("\"%s\";", extragen.tip_doc_SF.trim());
				else
					sLinea += String.format("\"\";");
				
				/* NRO DOCUMENTO */
				if(!extragen.tip_doc.trim().equals("DEF") && 
					extragen.nro_doc != null && extragen.nro_doc != 0 && 
					extragen.nro_doc != 1111 && extragen.nro_doc != 11111 &&
					extragen.nro_doc != 111111 && extragen.nro_doc != 1111111)
					sLinea += String.format("\"%.0f\";", extragen.nro_doc);
				else
					sLinea += String.format("\"\";");
			}
		}else{
			/* TIPO DOCUMENTO */
			if(extragen.tip_doc !=null && !extragen.tip_doc.trim().equals("DEF"))
				sLinea += String.format("\"%s\";", extragen.tip_doc_SF.trim());
			else
				sLinea += String.format("\"\";");
			
			/* NRO DOCUMENTO */
			if(!extragen.tip_doc.trim().equals("DEF") && 
					extragen.nro_doc != null && extragen.nro_doc != 0 && 
					extragen.nro_doc != 1111 && extragen.nro_doc != 11111 &&
					extragen.nro_doc != 111111 && extragen.nro_doc != 1111111)
				sLinea += String.format("\"%.0f\";", extragen.nro_doc);
			else
				sLinea += String.format("\"\";");
		}
		
		/* EMAIL 1 */
		if(!extragen.email_1.trim().equals("NO TIENE"))
			sLinea += String.format("\"%s\";", extragen.email_1.trim());
		else
			sLinea += String.format("\"\";");
				
		/* EMAIL 2 */
		if(!extragen.email_1.trim().equals("NO TIENE"))
			sLinea += String.format("\"%s\";", extragen.email_2.trim());
		else
			sLinea += String.format("\"\";");
					
		/* TELEFONO PPAL */
		if(extragen.telefono != null)
			sLinea += String.format("\"%s\";", extragen.telefono.trim());
		else
			sLinea += String.format("\"\";");
				
		/* CELULAR */
		if(extragen.telefono_celular != null)
			sLinea += String.format("\"%s\";", extragen.telefono_celular.trim());
		else
			sLinea += String.format("\"\";");
					
		/* TELEFONO SEC */
		if(extragen.telefono_secundario != null)
			sLinea += String.format("\"%s\";", extragen.telefono_secundario.trim());
		else
			sLinea += String.format("\"\";");
					
		/* MONEDA */
		sLinea += String.format("\"ARS\";");
		
		/* TIPO REGISTRO */
	    /*
		if(extragen.es_empresa[0]=='S'){
			sLinea += String.format("\"B2B\";");
		}else{
			sLinea += String.format("\"B2C\";");
		}
	    */
		sLinea += String.format("\"B2C\";");
		
		/* FECHA NACIMIENTO (VACIO) */
		sLinea += String.format("\"\";");
		/* CTA.PPAL (VACIO) */
		sLinea += String.format("\"\";");
		/* APELLIDO MATERNO (VACIO) */
		sLinea += String.format("\"\";");
		/* APELLIDO PATERNO  */
		sLinea += String.format("\".\";");
		
		/* DIRECCION */
		sLinea += String.format("%s\"%d-2ARG\";", sLinea, extragen.numero_cliente);
		
		/* EJECUTIVO (VACIO) */
		sLinea += String.format("\"\";");
		/* GIRO (VACIO) */
		sLinea += String.format("\"\";");
		/* CLASE SERVICIO (VACIO) */
		sLinea += String.format("\"\";");
		
		/* ID EMPRESA */
		sLinea += String.format("\"9\";");
		
		/* NOMBRE DE LA EMPRESA */
		if(extragen.es_empresa != null && extragen.es_empresa.trim().equals("S"))
			sLinea += String.format("%s\"%s\";", sLinea, extragen.nombre.trim());
		else
			sLinea += String.format("\"\";");
		
	    /* Tipo IVA */
		if(extragen.tipoIva != null)
			sLinea += String.format("\"%s\";", extragen.tipoIva.trim());
		else
			sLinea += String.format("\"\";");

	    /* Email Adicional */
	  	if(!extragen.email_3.trim().equals("NO TIENE"))
	  		sLinea += String.format("\"%s\";", extragen.email_3.trim());
		else
			sLinea += String.format("\"\";");
			   
	  	/* Tipo de Cuenta */
	  	if(extragen.es_empresa != null && extragen.es_empresa.trim().equals("S"))
	  		sLinea += String.format("\"Persona Juridica\";");
	  	else
	  		sLinea += String.format("\"Persona Fisica\";");
	   	  
	  	/* CuentaCliente  */
	  	sLinea += String.format("\"%d\";", extragen.numero_cliente);
	      
	  	/* Cuenta Padre */
	  	if(extragen.papa_t23 != null)
	  		sLinea += String.format("\"%sARG\";", extragen.papa_t23.trim());
	  	else if(extragen.minist_repart > 0)
	  		sLinea += String.format("\"%d\";", extragen.minist_repart);
	  	else
	  		sLinea += String.format("\"\";");
	   	         
	  	/* Clase de Cuenta */
	  	if(extragen.sClaseServicio != null)
	  		sLinea += String.format("\"%s\";", extragen.sClaseServicio.trim());
	  	else
	  		sLinea += String.format("\"\";");
	   
	  	/* Tipo de Sociedad */
	  	sLinea += String.format("\"\";");

		sLinea += "\r\n";
		
		try {
			outFileCuenta.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}

	private Boolean InformaContactos(ExtragenDTO extragen) throws SQLException {
		String sLinea = "";
		
		/* ID */
		sLinea = String.format("\"%dARG\";", extragen.numero_cliente);
		
		/* NOMBRE */
		sLinea += String.format("\"%s\";", extragen.nombre.trim());
		
		/* APELLIDO (VACIO) */
		sLinea += String.format("\".\";");
		/* SALUDO (VACIO) */
		sLinea += String.format("\"\";");
		
		/* NOMBRE CUENTA */
		sLinea += String.format("\"%dARG\";", extragen.numero_cliente);
		
		/* ESTADO CIVIL (VACIO) */
		sLinea += String.format("\"\";");
		/* GENERO (VACIO) */
		sLinea += String.format("\"\";");
/*
		if(!StringUtils.equals(extragen.tip_doc, ""))
			/ TIPO DOCUMENTO /
			sLinea += String.format("\"%s\";", extragen.tip_doc);
		else
			/ TIPO DOCUMENTO /
			sLinea += String.format("\"\";");
*/
		/* TIPO DOCUMENTO */
		if(extragen.tip_doc !=null && !extragen.tip_doc.trim().equals("DEF"))
			sLinea += String.format("\"%s\";", extragen.tip_doc.trim());
		else
			sLinea += String.format("\"\";");
		
		/* NRO DOCUMENTO */
		if(!extragen.tip_doc.trim().equals("DEF") &&  
				extragen.nro_doc != null && extragen.nro_doc != 0 && 
				extragen.nro_doc != 1111 && extragen.nro_doc != 11111 &&
				extragen.nro_doc != 111111 && extragen.nro_doc != 1111111)
			sLinea += String.format("\"%.0f\";", extragen.nro_doc);
		else
			sLinea += String.format("\"\";");

		if(extragen.nro_doc != null)
			/* NRO DOCUMENTO */
			sLinea += String.format("\"%.0f\";", extragen.nro_doc);
		else
			/* NRO DOCUMENTO */
			sLinea += String.format("\"\";");
				
		/* ETAPA */
		sLinea += String.format("\"Active Customer\";");
		
		/* ESTRATO (VACIO) */
		sLinea += String.format("\"\";");
		/* NIVEL EDUCATIVO (VACIO) */
		sLinea += String.format("\"\";");
		/* AUTORIZACION DATOS (VACIO) */
		sLinea += String.format("\"\";");
		/* NO LLAMAR (VACIO) */
		sLinea += String.format("\"\";");
		/* NO CORREO (VACIO) */
		sLinea += String.format("\"\";");
		/* PROFESION (VACIO) */
		sLinea += String.format("\"\";");
		/* OCUPACION (VACIO) */
		sLinea += String.format("\"\";");
		/* Fecha Nacimiento (VACIO) */
		sLinea += String.format("\"\";");
		
		/* CANAL CONTACTO */
		/*	
		if(!StringUtils.equals(extragen.email_1, "NO TIENE")){
			sLinea += String.format("%s;", extragen.email_1);
		}else if(!StringUtils.equals(extragen.telefono, "")){
			sLinea += String.format("%s;", extragen.telefono);
		}else if(!StringUtils.equals(extragen.telefono_secundario, "")){
			sLinea += String.format("%s;", extragen.telefono_secundario);
		}else if(!StringUtils.equals(extragen.telefono_celular, "")){
			sLinea += String.format("%s;", extragen.telefono_celular);
		}else{
			sLinea += String.format(";");	
		}
	 	*/
		if(!extragen.email_1.trim().equals("NO TIENE"))
			sLinea += String.format("\"CAN006\";");
		else
			sLinea += String.format("\"CAN003\";");
	   			
		/* EMAIL 1 */
		if(!extragen.email_1.trim().equals("NO TIENE"))
			sLinea += String.format("\"%s\";", extragen.email_1.trim());
		else
			sLinea += String.format("\"\";");
				
		/* EMAIL 2 */
		if(!extragen.email_2.trim().equals("NO TIENE"))
			sLinea += String.format("\"%s\";", extragen.email_2.trim());
		else
			sLinea += String.format("\"\";");
					
		/* TELEFONO PPAL */
		if(extragen.telefono != null)
			sLinea += String.format("\"%s\";", extragen.telefono.trim());
		else
			sLinea += String.format("\"\";");
				
		/* TELEFONO SEC */
		if(extragen.telefono_secundario != null)
			sLinea += String.format("\"%s\";", extragen.telefono_secundario.trim());
		else
			sLinea += String.format("\"\";");
			
		/* CELULAR */
		if(extragen.telefono_celular != null)
			sLinea += String.format("\"%s\";", extragen.telefono_celular.trim());
		else
			sLinea += String.format("\"\";");
					
		/* MONEDA */
		sLinea += String.format("\"ARS\";");
		
		/* APELLIDO PATERNO (.) */
		sLinea += String.format("\".\";");
		
		/* APELLIDO MATERNO (VACIO) */
		sLinea += String.format("\"\";");
		/* TIPO ACREDITACION (VACIO) */
		sLinea += String.format("\"\";");
		/* DIRECC.DEL CONTACTO  */
		sLinea += String.format("\"%d-2ARG\";", extragen.numero_cliente);
		
		/* USR TWITTER (VACIO) */
		sLinea += String.format("\"\";");
		/* SEGUIDORES TWITTER (VACIO) */
		sLinea += String.format("\"\";");
		/* INFLUENCIA (VACIO) */
		sLinea += String.format("\"\";");
		/* TIPO INFLUENCIA (VACIO) */
		sLinea += String.format("\"\";");
		/* BIO TWITTER (VACIO) */
		sLinea += String.format("\"\";");
		/* ID USR TWITTER (VACIO) */
		sLinea += String.format("\"\";");
		/* USR FACEBOOK (VACIO) */
		sLinea += String.format("\"\";");
		/* ID USR FACBOOK (VACIO) */
		sLinea += String.format("\"\";");
		/* ID EMPRESA */
		sLinea += String.format("\"9\";");
		
		sLinea += "\r\n";
		
		try {
			outFileContacto.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}

	private Boolean InformaPointerDelivery(ExtragenDTO extragen) throws SQLException {
		String sLinea = "";
		String sAux = "";
		
		/* Identificador POD */
		sLinea = String.format("\"%dAR\";", extragen.numero_cliente);
	   
		/* NUMERO POD */
		sLinea += String.format("\"%d\";", extragen.numero_cliente);
	
		/* MONEDA */
		sLinea += String.format("\"ARS\";");
		
		/* DV (VACIO) */
		sLinea += String.format("\"\";");
		
		/* DIRECCION */
		sLinea += String.format("\"%d-2ARG\";", extragen.numero_cliente);
		
		/* ESTADO POD */
		sLinea += String.format("\"0\";");
		
		/* PAIS */
		sLinea += String.format("\"ARGENTINA\";");
		
		/* COMUNA (VACIO) */
		sLinea += String.format("\"\";");
		
		/* TIPO SEGMENTO (VACIO) */
		sLinea += String.format("\"BT\";");
		
		/* MED.DICIPLINA (VACIO) */
		sLinea += String.format("\"\";");
		
		/* ID EMPRESA */
		sLinea += String.format("\"9\";");
		
		/* ELECTRODEPENDIENTE */
		if(extragen.electrodependiente != null) {
			sLinea += String.format("\"%s\";", extragen.electrodependiente.trim());
		}else {
			sLinea += String.format("\"\";");
		}
		
		
		/* TARIFA */
		if(extragen.tarifa != null) {
			sLinea += String.format("\"%s\";", extragen.tarifa.trim());
		}else {
			sLinea += String.format("\"\";");
		}
		
		
		/* TIPO AGRUPA (VACIO) */
		sLinea += String.format("\"T1\";");
		
		/* FULL ELECTRIC (VACIO) */
		sLinea += String.format("\"\";");
		
		/* NOMBRE BOLETA */
		if(extragen.nombre != null) {
			sLinea += String.format("\"%s\";", extragen.nombre.trim());
		}else {
			sLinea += String.format("\"\";");
		}
		
		/* RUTA (VACIO) */
		sLinea += String.format("\"\";");
			
		/* DIRECCION DE REPARTO */
		if(extragen.tec_nom_calle != null) {
			sAux = String.format("%s %s ", extragen.tec_nom_calle.trim(), extragen.tec_nro_dir.trim());
			if(extragen.tec_piso_dir != null )
				sAux += String.format("piso %s ", extragen.tec_piso_dir.trim());	
			
			if(extragen.tec_piso_dir != null)
				sAux += String.format("Dpto. %s", extragen.tec_depto_dir.trim());	
		}
		
		if(sAux != null)		
			sLinea += String.format("\"%s\";", sAux.trim());
		else
		    sLinea += String.format("\"\";");
		   		   
		/* COMUNA DE REPARTO */
		if(extragen.tec_cod_local != null)
			sLinea += String.format("\"%s\";", extragen.tec_cod_local.trim());
		else
			sLinea += String.format("\"\";");
		   			
		/* NRO.TRANSFORMADOR */
		if(extragen.tec_centro_trans != null)
			sLinea += String.format("\"%s\";", extragen.tec_centro_trans.trim());
		else
			sLinea += String.format("\"\";");
				
		/* TIPO TRANSFORMADOR */
		if(!StringUtils.equals(extragen.tipo_tranformador, ""))
			/*sLinea += String.format("%s%s;", sLinea, extragen.tipo_tranformador);*/
			sLinea += String.format("\"\";");
		else
			sLinea += String.format("\"\";");
				
		/* TIPO CONEXION */
		if(extragen.cod_voltaje != null && extragen.cod_voltaje != null){
			if(Integer.parseInt(extragen.cod_voltaje)==1)
				sLinea += String.format("\"MF\";");
			else
				sLinea += String.format("\"TF\";");
		} else
			sLinea += String.format("\"\";");
					
		/* ESTRATO (VACIO) */
		sLinea += String.format("\"\";");
		
		/* SUBESTACION */
		if(extragen.tec_subestacion != null)
			sLinea += String.format("\"%s\";", extragen.tec_subestacion.trim());
		else
			sLinea += String.format("\"\";");
					
		/* COND.INSTALACION (VACIO) */
		sLinea += String.format("\"\";");
		
		/* NRO ALIMENTADOR */
		if(extragen.tec_alimentador != null)
			sLinea += String.format("\"%s\";", extragen.tec_alimentador.trim());
		else
			sLinea += String.format("\"\";");
				
		/* TIPO LECTURA */
		sLinea += String.format("\"8\";");
		
		/* BLOQUE (VACIO) */
		sLinea += String.format("\"%s\";", extragen.sucursal );
		
		/* HORAIO RACIONAMIENTO(VACIO) */
		sLinea += String.format("\"\";");
		
		/* ESTADO CONEXION */
		sLinea += String.format("\"0\";");
		
		/* FECHA ULTIMO CORTE */
		if(extragen.ultimo_corte != null)
			sLinea += String.format("\"%sT00:00:00.000Z\";", extragen.ultimo_corte);
		else
			sLinea += String.format("\"\";");	
				
		/* COD.PRC (VACIO) */
		sLinea += String.format("\"\";");
		/* SED (VACIO) */
		sLinea += String.format("\"\";");
		/* SET (VACIO) */
		sLinea += String.format("\"\";");
		/* LLAVE (VACIO) */
		sLinea += String.format("\"\";");
		/* POTENCIA */
		if(extragen.potencia_inst_fp >0.00)
			sLinea += String.format("\"%.02f\";", extragen.potencia_inst_fp);
		else
			sLinea += String.format("\"\";");
		   
		/* CLIENTE SINGULAR (VACIO) */
		sLinea += String.format("\"\";");
		
		/* CLASE SERVICIO */
		/*
		sLinea += String.format("%s%s;", sLinea, extragen.sClaseServicio);
		*/
		sLinea += String.format("\"%s\";", extragen.tipo_cliente);
		
		/* SUB CLASE SERVICIO */
		/*sLinea += String.format("%s\"%s\";", sLinea, extragen.sSubClaseServ);*/
		sLinea += String.format("\"\";");
		
		/* RUTA LECTURA */
		sLinea += String.format("\"%s%d%d%d\";", extragen.sucursal, extragen.sector, extragen.zona, extragen.correlativo_ruta);
		
		/* TIPO LIQUIDACION (VACIO) */
		sLinea += String.format("\"\";");
		/* MERCADO (VACIO) */
		sLinea += String.format("\"\";");
		/* CARGA AFORADA (VACIO) */
		sLinea += String.format("\"\";");
		
		/* ANO FABRICACION */
		sLinea += String.format("\"%d\";", extragen.medidor_anio);
		   
		/* CANT.PERSONAS EN PUNTO DE SUMINISTRO */
		sLinea += String.format("\"\";");
		   
		/* Nro.DCI */
		if(extragen.nro_dci != null && extragen.nro_dci > 0)
			sLinea += String.format("\"%.0lf\";", extragen.nro_dci);
		else
			sLinea += String.format("\"\";");
		   
		/* Organismo */
		if(extragen.orga_dci != null)
			sLinea += String.format("\"%s\";", extragen.orga_dci);
		else
			sLinea += String.format("\"\";");
		   
		/* Potencia Convenida */
		sLinea += String.format("\"\";");
		
		/* Fecha Desconexion */
		sLinea += String.format("\"\";");
		   
		sLinea += "\r\n";
		
		try {
			outFilePoint.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
	private Boolean GeneraServiceProduct(ExtragenDTO extragen) throws SQLException {
		String sLinea = "";
		String sAux = "";

		/* ACTIVO */	
		sLinea = String.format("\"%dARG\";", extragen.numero_cliente);
		
		/* CONTACTO */
		sLinea += String.format("\"%dARG\";", extragen.numero_cliente);
		
		/* CUENTA */
		sLinea += String.format("\"%dARG\";", extragen.numero_cliente);
		
		/* PAIS */
		sLinea += String.format("\"ARGENTINA\";");
		
		/* COMPANIA */
		sLinea += String.format("\"9\";");

		/* EXTERNAL ID */
		sLinea += String.format("\"%dSPRARG\";", extragen.numero_cliente);

		/* CONTACTO PRINCIPAL */
		sLinea += String.format("\"TRUE\";");
	   
		/* ElectroDependiente*/
		if(extragen.electrodependiente.trim().equals("1")) {
			/* Electro */
			/*sLinea += String.format("\"TRUE\";");*/
			sLinea += String.format("\"FALSE\";");
			/* Nro.DCI */
			if(extragen.nro_dci != null && extragen.nro_dci > 0)
				sLinea += String.format("\"%.0lf\";", extragen.nro_dci);
			else
				sLinea += String.format("\"\";");
	     	      
			/* Organismo */
			if(extragen.orga_dci != null) {
				sLinea += String.format("\"%s\";", extragen.orga_dci.trim());
			}else {
				sLinea += String.format("\"\";");
			}
			
		} else {
		   /* Electro */
		   sLinea += String.format("\"FALSE\";");
		   /* DCI */
		   sLinea += String.format("\"\";");
		   /* Organismo */
		   sLinea += String.format("\"\";");
	   	}

		sLinea += "\r\n";
		
		try {
			outFileService.write(sLinea);
		}catch(Exception e) {
			e.printStackTrace();
		}
		
		return true;
	}
	
	private Boolean GeneraAsset(ExtragenDTO extragen) throws SQLException {
		String sLinea = "";
		String sAux = "";

		/* ID */
		sLinea = String.format("\"%dARG\";", extragen.numero_cliente);
		
		/* NOMBRE */
		/*sLinea += String.format("%s\"%s\";", sLinea, extragen.nombre);*/
		sLinea += String.format("\"Tarifa T1-%d\";", extragen.numero_cliente);
	   
		/* CUENTA */
		sLinea += String.format("\"%dARG\";", extragen.numero_cliente);
		
		/* CONTACTO */
		sLinea += String.format("\"%dARG\";", extragen.numero_cliente);
		
		/* SUMINISTRO */
		sLinea += String.format("\"%dAR\";", extragen.numero_cliente);
		
		/* DESCRIPCION */
		sLinea += String.format("\"%s\";", extragen.nombre);
		
		/* PRODUCTO */
		sLinea += String.format("\"%dSPRARG\";", extragen.numero_cliente);
		
		/* ESTADO */
	   if(extragen.estado_cliente.trim().equals("0"))
	      sLinea += String.format("\"Installed\";");
	   else
	      sLinea += String.format("\"Unsuscribed\";");
	   	   
	   /* Contacto Principal */
		sLinea += String.format("\"TRUE\";");
		
	   /* Contrato */
	   sLinea += String.format("\"%dCTOARG\";", extragen.numero_cliente);
	   
	   /* Estado Contratacion */
	   if(extragen.estado_cliente.trim().equals("0"))
	      sLinea += String.format("\"Active\";");
	   else
	      sLinea += String.format("\"Inactive\";");
	   
	   sLinea += "\r\n";
		
	   try {
		   outFileAsset.write(sLinea);
	   }catch(Exception e) {
		   e.printStackTrace();
	   }
		
	   return true;
	}
}
