package ppal;

import java.util.Date;
import java.text.SimpleDateFormat;

import servicios.CnrSRV;
import servicios.ConvenioSRV;

public class sfc_convenios {
	static private int iModoExtraccion; 
	static private String sOS;

	public static void main(String[] args) {
		ConvenioSRV miSrv = new ConvenioSRV();
		SimpleDateFormat fechaF = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
		
		Date fechaInicio = new Date();
		
		if(!ValidaArgumentos(args)) {
			System.exit(1);
		}
		System.out.println("Procesando CONVENIOS ...");
		

		if(!miSrv.ProcesaConve(iModoExtraccion, sOS)) {
			System.out.println("Fallo el proceso");
			System.exit(1);
		}
		
		System.out.println("Termino OK");
		
		Date fechaFin = new Date();
		
		System.out.println("Inicio: " + fechaF.format(fechaInicio));
		System.out.println("Fin:    " + fechaF.format(fechaFin));

	}

	static private Boolean ValidaArgumentos(String[] args) {
		
		if(args.length != 2) {
			System.out.println("Argumentos Invalidos");
			System.out.println("Modo Extraccion: 0=Normal; 1=Reducida");
			System.out.println("Plataforma: DOS o UNIX");
			
			return false;
		}
		
		iModoExtraccion= Integer.parseInt(args[0]);
		sOS=args[1];
		
		return true;
	}
	
	
}
