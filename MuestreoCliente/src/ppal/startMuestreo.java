package ppal;

import javax.swing.*;
import entidades.ClienteDTO;
import dao.ClientesDAO;
import servicios.*;

public class startMuestreo {

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		String sOS=args[0];
		System.out.println("SO = " + sOS);
		//ClienteIndividual();

		//MoveIn();
		
		UniversoSAP();
		
		//ContratoSFC(sOS);
	}

	
	private static void UniversoSAP() {
		universoSRV miSrv = new universoSRV();
		
		System.out.println("Iniciando Carga");
		
		if(! miSrv.CargaUniversoSAP()) {
			System.exit(1);
		}
		
		System.out.println("Carga Terminada OK");
	}
	
	private static void ClienteIndividual() {
		String sNroCliente;
		long lNroCliente;
		ClientesDAO miSrv = new ClientesDAO();
		ClienteDTO miReg = null;
		
		sNroCliente = JOptionPane.showInputDialog("Ingrese Nro.Cliente");
		lNroCliente=Long.parseLong(sNroCliente);
		
		miReg=miSrv.getCliente(lNroCliente);
		
		JOptionPane.showMessageDialog(null, "Sucursal Cliente " + miReg.sucursal);
		
	}
	
	private static void MoveIn() {
		servicios.MoveInSRV miSrv = new servicios.MoveInSRV();
		
		System.out.println("Procesando..");
		
		if( miSrv.GenMoveIn()) {
			JOptionPane.showMessageDialog(null,  "Termine");
		}else {
			JOptionPane.showMessageDialog(null,"FAllo");
		}
	}
	
/*
	private static void ContratoSFC(String sOS) {
		servicios.sfcContrato miSrv = new servicios.sfcContrato();

		System.out.println("Procesando..");
		
		if( miSrv.genContratoSFC(sOS)) {
			//JOptionPane.showMessageDialog(null,  "Termine");
			System.out.println("Termine");
		}else {
			//JOptionPane.showMessageDialog(null,"FAllo");
			System.out.println("Fallo");
		}
	}
*/	
}
