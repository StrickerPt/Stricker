global class sh_CustomManager implements Schedulable{

    global Integer pagina{get;set;}
    global Integer maxPagina{get;set;}
    global String ultimaData{get;set;}
    
    global sh_CustomManager(){
        pagina = 1;
        maxPagina = 1;
    }
    
    global sh_CustomManager(Integer pagina, Integer maxPagina,String ultimaData){
        this.pagina = pagina;
        this.maxPagina = maxPagina;
        this.ultimaData = ultimaData;
    }
    
    global void execute(SchedulableContext sc) {
        if(ultimaData == null){
            ultimaData = System.now().addDays(-1).format('yyyy-MM-dd');
        }
        ProductManager.initCustomizacoes(pagina, maxPagina, ultimaData);
    }
}