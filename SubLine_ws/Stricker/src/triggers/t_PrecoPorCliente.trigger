/*Trigger to assure that there are no records created for the same customer, with the same product, with concurrent time spans.
* 
*/
trigger t_PrecoPorCliente on Preco_por_cliente__c (before insert, after insert, before update, after update, after delete){
    if(checkRecursive.runPrecoCliente){
        if(Trigger.isBefore){
        //********************************************************************COMPARACAO DE ENTRADAS COM O MESMO PRODUTO NO MESMO ESPACO TEMPORAL
            if(Trigger.isInsert || Trigger.isUpdate){
                Set<Id> accIds = new Set<Id>();
                Set<Id> prodIds = new Set<Id>();
                Map<String, List<Preco_por_cliente__c>> comparePricesInTrigger = new Map<String, List<Preco_por_cliente__c>>();
                for(Preco_por_cliente__c pc : Trigger.new){
                    accIds.add(pc.Cliente__c);
                    prodIds.add(pc.Produto__c);
                    
                    //compara registos que entraram no trigger ao mesmo tempo.
                    String key = '' + pc.Cliente__c + pc.Produto__c;
                    if(!comparePricesInTrigger.containsKey(key)) comparePricesInTrigger.put(key, new List<Preco_por_cliente__c>());
                    
                    for(Preco_por_cliente__c pc2 : comparePricesInTrigger.get(key)){
                        if((pc.Data_de_inicio__c >= pc2.Data_de_inicio__c && pc.Data_de_inicio__c <= pc2.Data_de_fim__c)
                           || (pc.Data_de_fim__c >= pc2.Data_de_inicio__c && pc.Data_de_fim__c <= pc2.Data_de_fim__c)){
                               String code = [Select Id, ProductCode From Product2 Where Id = :pc2.Produto__c].ProductCode;
                               String client = [Select Id, Numero_de_cliente__c From Account Where Id = :pc.Cliente__c].Numero_de_cliente__c;
                               String lab = Utils.getObjectFieldLabel('Product2', 'ProductCode');
                               String lab2 = Utils.getObjectFieldLabel('Account', 'Numero_de_cliente__c');
                               
                               pc.addError(Label.Preco_de_cliente_mesmo_periodo + ' ' + lab2 + ':' + client + '; ' + lab + ': ' + code);
                               checkRecursive.runPrecoCliente = false;
                               return;
                           }
                    }
                    comparePricesInTrigger.get(key).add(pc);
                }
                
                
                //Compara registos que estão no trigger com os já existentes na base de dados
                Map<Id,Account> accs = new Map<Id,Account>([Select Id, 
                                                            (Select Id,Produto__c,Data_de_inicio__c,Data_de_fim__c 
                                                             From Precos_por_Cliente__r Where Id Not In :Trigger.new And Produto__c In :prodIds) 
                                                            From Account Where Id In :accIds]);
                
                for(Preco_por_cliente__c pc : Trigger.new){
                    if(accs.containsKey(pc.Cliente__c)){
                        for(Preco_por_cliente__c pc2 : accs.get(pc.Cliente__c).Precos_por_Cliente__r){
                            if(pc.Produto__c == pc2.Produto__c){
                                if((pc.Data_de_inicio__c >= pc2.Data_de_inicio__c && pc.Data_de_inicio__c <= pc2.Data_de_fim__c)
                                   || (pc.Data_de_fim__c >= pc2.Data_de_inicio__c && pc.Data_de_fim__c <= pc2.Data_de_fim__c)){
                                       String code = [Select Id, ProductCode From Product2 Where Id = :pc2.Produto__c].ProductCode;
                                       String client = [Select Id, Numero_de_cliente__c From Account Where Id = :pc.Cliente__c].Numero_de_cliente__c;
                                       String lab = Utils.getObjectFieldLabel('Product2', 'ProductCode');
                                       String lab2 = Utils.getObjectFieldLabel('Account', 'Numero_de_cliente__c');
                                       
                                       pc.addError(Label.Preco_de_cliente_mesmo_periodo + ' ' + lab2 + ':' + client + ';' + lab + ': ' + code);
                                       checkRecursive.runPrecoCliente = false;
                                       return;
                                   }
                            }
                        }
                    }
                }
            }
        }else{
            if(Trigger.isInsert || Trigger.isUpdate){
                /* Envia pedidos consoante o numero de linhas mexidas agrupadas por cliente
                 * Existindo mais que uma linha alterada nos PPC de um cliente irá ser enviado um pedido de criação de dossier no PHC
                 * Existindo apenas uma linha mexida por cada cliente, cada um irá ter o seu dossier actualizado do lado do PHC
                 */
                /*Map<String, List<Preco_por_cliente__c>> accMap = new Map<String, List<Preco_por_cliente__c>>();
                for(Preco_por_cliente__c pc : Trigger.new){
                    if(!accMap.containsKey(pc.Cliente__c)) accMap.put(pc.Cliente__c, new List<Preco_por_cliente__c>());
                    accMap.get(pc.Cliente__c).add(pc);
                }
                for(String key : accMap.keySet()){
                    if(accMap.get(key).size() > 1){
                        Integrator.criaPrecosCliente(key);
                    }else{
                        Integrator.updatePrecosCliente(key);
                    }
                }*/
                String jobName = 'Insert/Update PPC';
                List<CronTrigger> jobs = [Select Id From CronTrigger Where CronJobDetailId In (SELECT Id FROM CronJobDetail Where Name = :jobName)];
                if(!jobs.isEmpty()){
                    for(CronTrigger job : jobs){
                        System.abortJob(job.Id);
                    }
                }
                DateTime now  = DateTime.now();
                String nowToString = String.ValueOf(now);
                DateTime nextRunTime = now.addMinutes(2);
                String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
                
                sh_PrecosPorCliente sc = new sh_PrecosPorCliente();
                System.schedule(jobName, cronString, sc);
            }else if(Trigger.isDelete){
                /*Map<String, List<Preco_por_cliente__c>> accMap = new Map<String, List<Preco_por_cliente__c>>();
                for(Preco_por_cliente__c pc : Trigger.old){
                    if(!accMap.containsKey(pc.Cliente__c)) accMap.put(pc.Cliente__c, new List<Preco_por_cliente__c>());
                    accMap.get(pc.Cliente__c).add(pc);
                }
                for(String key : accMap.keySet()){
                    Integrator.criaPrecosCliente(key);
                }*/
                
                String jobName = 'Delete PPC';
                List<CronTrigger> jobs = [Select Id From CronTrigger Where CronJobDetailId In (SELECT Id FROM CronJobDetail Where Name = :jobName)];
                if(!jobs.isEmpty()){
                    for(CronTrigger job : jobs){
                        System.abortJob(job.Id);
                    }
                }
                DateTime now  = DateTime.now();
                String nowToString = String.ValueOf(now);
                DateTime nextRunTime = now.addMinutes(2);
                String cronString = '' + nextRunTime.second() + ' ' + nextRunTime.minute() + ' ' + nextRunTime.hour() + ' ' + nextRunTime.day() + ' ' + nextRunTime.month() + ' ? ' + nextRunTime.year(); 
                
                sh_DeletePrecoPorCliente sc = new sh_DeletePrecoPorCliente();
                System.schedule(jobName, cronString, sc);
            }
        }
    }
}