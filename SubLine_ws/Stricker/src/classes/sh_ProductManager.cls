global class sh_ProductManager implements Schedulable{
    
    global Integer pagina{get;set;}
    global Integer maxPagina{get;set;}
    global String ultimaData{get;set;}
    global boolean isAuto{get;set;}
    
    global sh_ProductManager(){
        pagina = 1;
        maxPagina = 1;
        isAuto = true;
    }
    
    global sh_ProductManager(Integer pagina, Integer maxPagina,String ultimaData){
        this.pagina = pagina;
        this.maxPagina = maxPagina;
        this.ultimaData = ultimaData;
        isAuto = false;
    }
    
    global void execute(SchedulableContext sc) {
        if(isAuto == null) isAuto = true;
        if(isAuto){
            ultimaData = System.now().addDays(-1).format('yyyy-MM-dd');
        }
        ProductManager.initProdutos(pagina, maxPagina,ultimaData);
    }
    
}