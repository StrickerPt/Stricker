global class sh_inactiveProducts implements Database.Batchable<sObject>, Database.Stateful,  Schedulable, Database.AllowsCallouts{
    global Integer pagina{get;set;}
    global Integer maxPagina{get;set;}
    global String ultimaData{get;set;}

    
    public sh_inactiveProducts(){
    } 
    
    global void execute(SchedulableContext SC) {           
        sh_inactiveProducts b = new sh_inactiveProducts(); 
        database.executebatch(b);        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){ 
        return Database.getQueryLocator([SELECT Id,IsActive FROM Product2 Where RecordType.Name != 'Taxa' And ProductCode != 'NSGEN' and isActive = true]);
    
    }
    
    global void execute(Database.BatchableContext BC, List<Product2> products){
        List<Product2> l_productsToInactive = new List<Product2>();
        for(Product2 p : products){
            p.IsActive = false;
            l_productsToInactive.add(p);
        }                  
          
        if(!l_productsToInactive.isEmpty()){
            update l_productsToInactive;
        }
    }
    
    global void finish(Database.BatchableContext BC){
        pagina = 1;
        maxPagina = 1;
            //ultimaData = System.now().addDays(-1).format('yyyy-MM-dd');
		ultimaData = System.now().addYears(-1).format('yyyy-MM-dd');
         DateTime now  = DateTime.now();
            String nowToString = String.ValueOf(now);
            DateTime nextRunTime = now.addSeconds(15);
            String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
            
            
            sh_ProductManager sc = new sh_ProductManager(pagina, maxPagina, ultimaData);
            System.schedule('Reagendamento - sh_ProductManager '+nowToString, cronString, sc);

    }
}