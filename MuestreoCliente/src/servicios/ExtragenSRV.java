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

	public Boolean ProcesoGral(int iTipo, int iEstado, String sOS) {
		iTipoCorrida=iTipo;
		iEstadoClientes=iEstado;
		
		//Abre Archivos
		if(!AbreArchivos(sOS)) {
			System.out.println("No se pudieron abrir los archivos. Proceso Abortado");
			System.exit(1);
		}
		
		ExtragenDAO miDao = new ExtragenDAO();
		
		//proceso ppal
		if(!miDao.ProcesoPpal(iTipo, iEstado)) {
			System.out.println("Fallo el DAO para Movimientos");
			return false;
		}
		
		
		//Cierra Archivos
		CierraArchivos();
	
		//Copiar Archivos
/*		
		if(!MoverArchivo()) {
			System.out.println("No se pudo mover los archivos.");
		}
*/
		return true;
	}
	
	public Boolean ProcesaCliente(long lNroCliente) {
		ExtragenDAO miDao = new ExtragenDAO();
		ExtragenDTO miClie = null;

		miClie = miDao.getClienteGral(lNroCliente);

		
		return true;
	}
	
	private Boolean AbreArchivos( String sOS) {
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

		
		sClave = "SALESF";
		sPathGenera=miDao.getRuta(sClave);
		sClave = "SALEFC";
		sPathCopia=miDao.getRuta(sClave);
		
		if(sOS.equals("DOS")){
			sPathGenera="C:\\Users\\ar17031095.ENELINT\\Documents\\data_in\\";
			sPathCopia="C:\\Users\\ar17031095.ENELINT\\Documents\\data_out\\";
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
	
	
}
