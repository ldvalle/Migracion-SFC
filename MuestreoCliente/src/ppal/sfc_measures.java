package ppal;

import servicios.MeasuresSRV;
import java.util.Date;
import java.text.SimpleDateFormat;

public class sfc_measures {
	static private int iEstadoCliente; 
	static private int iModoExtraccion; 
	static private int iTipoArchivos; 
	static private String sOS;

	public static void main(String[] args) {
		
		MeasuresSRV miSrv = new MeasuresSRV();
		SimpleDateFormat fechaF = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss");
		
		Date fechaInicio = new Date();
		
		if(!ValidaArgumentos(args)) {
			System.exit(1);
		}
/*		
		System.out.println(String.format("[%d] [%d] [%d] [%s]", iEstadoCliente, iModoExtraccion, iTipoArchivos, sOS));
		System.exit(1);
*/		
		System.out.println("Procesando ...");
		
		if(!miSrv.ProcesaMeasure(iEstadoCliente, iModoExtraccion, iTipoArchivos, sOS)) {
			System.out.println("Fallo el proceso");
			System.exit(1);
		}

		System.out.println("Termino OK");
		
		Date fechaFin = new Date();
		
		System.out.println("Inicio: " + fechaF.format(fechaInicio));
		System.out.println("Fin:    " + fechaF.format(fechaFin));
		
	}

	static private Boolean ValidaArgumentos(String[] args) {
		
		if(args.length != 4) {
			System.out.println("Argumentos Invalidos");
			System.out.println("Estado Cliente: 0=Activos; 1=No Activos");
			System.out.println("Modo Extraccion: 0=Normal; 1=Reducida");
			System.out.println("Archivos: 0=Todos; 1=Lecturas; 2=Consumos");
			System.out.println("Plataforma: DOS o UNIX");
			
			return false;
		}
		
		iEstadoCliente = Integer.parseInt(args[0]);
		iModoExtraccion= Integer.parseInt(args[1]);
		iTipoArchivos= Integer.parseInt(args[2]);
		sOS=args[3];
		
		return true;
	}
}
