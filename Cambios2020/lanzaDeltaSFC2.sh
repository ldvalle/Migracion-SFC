#!/bin/ksh
# Autor : Lucas Daniel Valle


if [ $# -lt 1 ] ; then
   echo "Error en los parametros"
   echo "Parametros :  1=Base de datos"
   echo "Parametros :  2=Fecha Desde (dd/mm/aaaa) Opcional "
   echo "Parametros :  3=Fecha Hasta (dd/mm/aaaa) Opcional "
   
   exit 1
fi

DBDATE=DMY4
export DBDATE

BASE=$1

EJEC=/synergia/mac/act/unix/ejec/odt
SQLCMD=/synergia/mac/act/unix/ejec/odt/sqlcmd

echo "Procesando, espere ..........."



if [ $# -eq 1 ] ; then
   #MES_ANTERIOR=$(print " SELECT lpad(decode(month(today) - 1, 0, 12, month(today) - 1), 2,0) FROM dual; " | $SQLCMD -d $BASE)
   #ANO_ACTUAL=$(print " SELECT YEAR(TODAY) FROM dual; " | $SQLCMD -d $BASE)
   #ANO=$ANO_ACTUAL
   
   #if [ $MES_ANTERIOR -eq 12 ] ; then
   #   $ANO= `expr $ANO_ACTUAL - 1`
   #fi
   #FAUX=${ANO}${MES_ANTERIOR}
   #FDESDE=01/${MES_ANTERIOR}/${ANO}
   
   #ultimoDia=$(cal $MES_ANTERIOR $ANO | awk '/^ *[0-9]/ { last = $NF } END { print last }')
   
   #FHASTA=${ultimoDia}/${MES_ANTERIOR}/${ANO}
   
   FDESDE=$(print " SELECT TO_CHAR(TODAY - 1, '%d/%m/%Y') FROM dual; " | $SQLCMD -d $BASE)
   FHASTA=${FDESDE}
fi

if [ $# -eq 3 ] ; then
   FDESDE=$2
   FHASTA=$3
fi

echo "Desde ${FDESDE} hasta ${FHASTA}"

#ini=$(print " 00:00:00")
#fin=$(print " 23:59:59")

DIAINI=$(print $FDESDE | cut -c 1-2)
MESINI=$(print $FDESDE | cut -c 4-5)
ANOINI=$(print $FDESDE | cut -c 7-10)

DIAFIN=$(print $FHASTA | cut -c 1-2)
MESFIN=$(print $FHASTA | cut -c 4-5)
ANOFIN=$(print $FHASTA | cut -c 7-10)

DT_DESDE=${ANOINI}-${MESINI}-${DIAINI}$ini
DT_HASTA=${ANOFIN}-${MESFIN}-${DIAFIN}$fin

echo "dt Desde ${DT_DESDE} dt hasta ${DT_HASTA}"

nohup ${EJEC}/sfc_cnr.exe synergia 1 ${FDESDE} ${FHASTA} >cnr.log 2>cnr.err &
nohup ${EJEC}/sfc_convenios.exe synergia 1 ${FDESDE} ${FHASTA} >conve.log 2>conve.err  &
#nohup ${EJEC}/sfc_device.exe synergia 1 ${FDESDE} ${FHASTA} >dev.log 2>dev.err &
nohup ${EJEC}/sfc_field_operation.exe synergia 1 ${DT_DESDE} ${DT_HASTA} >field.log 2>field.err &
nohup ${EJEC}/sfc_invoice.exe synergia 1 ${FDESDE} ${FHASTA} >invo.log 2>invo.err &
nohup ${EJEC}/sfc_measures.exe synergia  1 0 ${FDESDE} ${FHASTA} >mea.log 2>mea.err &
#nohup ${EJEC}/sfc_movimientos.exe synergia  1 ${DT_DESDE} ${DT_HASTA} >mov.log 2>mov.err &
#nohup ${EJEC}/sfc_street.exe synergia &

echo "Lanzados los que son entre fechas.. :)"

#nohup ${EJEC}/sfc_actuclie.exe synergia ${FDESDE} ${FHASTA}
nohup ${EJEC}/sfc_contrato.exe synergia 1 0 ${FDESDE} ${FHASTA} >contra.log 2>contra.err &
nohup ${EJEC}/sfc_extragen.exe synergia 0 1 ${FDESDE} ${FHASTA} >extra.log 2>extra.err &
 
echo "Termine :)"
