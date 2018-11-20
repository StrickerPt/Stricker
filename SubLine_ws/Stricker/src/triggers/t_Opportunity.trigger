trigger t_Opportunity on Opportunity (before update, after update, before delete) {
    
    BusinessHours bh = [SELECT Id, Name, IsActive, IsDefault, SundayStartTime, SundayEndTime, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, 
                        ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime, TimeZoneSidKey, SystemModstamp, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, LastViewedDate 
                        FROM BusinessHours Where Name = 'PT'];
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            if(checkRecursive.runOpportunityBeforeUpdate){
                checkRecursive.runOpportunityBeforeUpdate = false;
                Set<String> refs = new Set<String>();
                for(Referencias_limite_prod__c	ref : [Select id, Referencias__c From Referencias_limite_prod__c]){
                    for(String s : ref.Referencias__c.split(';')){
                        refs.add(s);
                    }
                }
                List<Pedido_de_Maquete__c> pedidos = new List<Pedido_de_Maquete__c>();
                //SLA para departamento de designers - produção de maquete
                SLA__mdt maquete = [Select Id, Horas__c, Minutos__c From SLA__mdt Where DeveloperName = 'Maquetes'];
                List<Pedido_de_Maquete__c> pedidosAtivos = new List<Pedido_de_Maquete__c>();
                Map<Id, Opportunity> oppMapsPedidos = new Map<Id, Opportunity>([Select Id, (Select id From Pedidos_de_maquete__r Where Ativo__c = true) From Opportunity Where Id In :Trigger.new]);
                for(Opportunity opp : trigger.new){
                    
                    if(opp.Estado_da_maquete__c != Trigger.oldMap.get(opp.Id).Estado_da_maquete__c && opp.Estado_da_maquete__c == 'Aprovada'){
                        opp.Data_de_aprovacao_de_maquete__c = System.now();
                    }
                    //CALCULO DA DATA LIMITE DE PRODUCAO
                    /*
                    * se Data de aprovação de maquete for preenchida e !Em Falta
					* se deixou de estar Em falta e já tem Data de aprovação de maquete
					* se Estado da maquete passou para Aprovada
                    */
                    if((opp.Data_de_aprovacao_de_maquete__c != Trigger.oldMap.get(opp.Id).Data_de_aprovacao_de_maquete__c
                        && opp.Data_de_aprovacao_de_maquete__c != null 
                        && Trigger.oldMap.get(opp.Id).Data_de_aprovacao_de_maquete__c == null
                        && !opp.Em_falta__c)
                       || (Trigger.oldMap.get(opp.Id).Em_falta__c 
                           && !opp.Em_falta__c 
                           && opp.Data_de_aprovacao_de_maquete__c != null)
                       || (opp.Estado_da_maquete__c != Trigger.oldMap.get(opp.Id).Estado_da_maquete__c 
                           && opp.Estado_da_maquete__c == 'Aprovada' && !opp.Em_falta__c)){
                               Datetime dataLimite;
                               if(opp.Valor_total_de_customizacao__c > 250 && opp.Data_de_aprovacao_de_maquete__c.hourGmt() > 12){
                                   
                                   dataLimite = HoursUtilities.getTime(opp.Data_de_aprovacao_de_maquete__c, 6, bh);
                               }else if(opp.Valor_total_de_customizacao__c > 250 && opp.Data_de_aprovacao_de_maquete__c.hourGmt() < 12){
                                   
                                   dataLimite = HoursUtilities.getTime(opp.Data_de_aprovacao_de_maquete__c, 5, bh);
                               }else{
                                   boolean isPresent = false;
                                   for(OpportunityLineItem oli : opp.OpportunityLineItems){
                                       if(refs.contains(oli.ProductCode) && oli.Quantity >= 5000){
                                           isPresent = true;
                                           break;
                                       }
                                   }
                                   if(isPresent){ 
                                       dataLimite = HoursUtilities.getTime(opp.Data_de_aprovacao_de_maquete__c, 6, bh);
                                   }
                                   else if(opp.Data_de_aprovacao_de_maquete__c.hourGmt() > 12){
                                       dataLimite = HoursUtilities.getTime(opp.Data_de_aprovacao_de_maquete__c, 4, bh);
                                   }else{
                                       dataLimite = HoursUtilities.getTime(opp.Data_de_aprovacao_de_maquete__c, 3, bh);
                                   }
                               }
                               //opp.Data_limite_de_producao__c = dataLimite;
                               //calculo da data expectavel de envio
                               if(opp.Data_de_envio__c == null) opp.Data_de_envio__c = dataLimite;
                           }
                    if(Trigger.oldMap.get(opp.Id).Data_limite_de_producao__c != null
                       && opp.Data_limite_de_producao__c != Trigger.oldMap.get(opp.Id).Data_limite_de_producao__c
                       && opp.Data_limite_de_producao__c > opp.Data_de_envio__c){
                           opp.Data_de_envio__c = opp.Data_limite_de_producao__c;
                       }
                    
                    //CALCULO DA DATA DE PEDIDO DE MAQUETE
                    boolean calculaMaquete = false;
                    if(opp.StageName == 'Pedido de maquete' && Trigger.oldMap.get(opp.Id).StageName != opp.StageName){
                        
                        //**************TODO************************INACTIVAR PEDIDOS ATIVOS
                        for(Pedido_de_maquete__c delPedido : oppMapsPedidos.get(opp.Id).Pedidos_de_maquete__r){
                            pedidosAtivos.add(delPedido);
                        }
                        opp.Data_do_pedido_de_maquete__c = System.now();
                        opp.Data_de_envio_de_maquete__c = null;
                        opp.Designer__c = null;
                        pedidos.add(new Pedido_de_Maquete__c(Oportunidade__c = opp.Id, Tipo__c = (opp.Estado_da_maquete__c == 'Em retificação' ? 'Retificação' : 'Original')));
                        calculaMaquete = true;
                        
                        //CALCULO DA DATA LIMITE DE MAQUETE
                        if(calculaMaquete){
                            system.debug(opp.Data_do_pedido_de_maquete__c);
                            Long slaTime = (((Integer) maquete.Horas__c)*60 + (Integer) maquete.Minutos__c)*60*1000;//SLA.Horas__c * horas
                            Datetime newDate = BusinessHours.addGMT(bh.Id, opp.Data_do_pedido_de_maquete__c, slaTime);
                            system.debug(newDate);
                            
                            opp.Data_limite_de_maquete__c = newDate;
                        }
                    }
                    if(opp.Estado_da_maquete__c != Trigger.oldMap.get(opp.Id).Estado_da_maquete__c){
                        
                        if(opp.Estado_da_maquete__c == 'Em aprovação do cliente' || opp.Estado_da_maquete__c == 'Pendente'){
                            opp.Data_de_envio_de_maquete__c = System.now();
                        }else if(opp.Estado_da_maquete__c == 'Suspenso'){
                            
                            opp.Inicio_de_pausa_de_maquete__c = System.now();
                            
                            /*
                            //calcula snapshot da hora a que foi feita a pausa
                            Long tempo = BusinessHours.diff(bh.Id, System.now(), opp.Data_limite_de_maquete__c)/1000/60;//minutos totais
                            Integer horas = Integer.valueOf(tempo/60);
                            Integer minutos = Integer.valueOf(tempo - (60*horas));
                            Time novaHora = Time.newInstance(Math.abs(horas), Math.abs(minutos), 0, 0);
                            opp.Snapshot_de_maquete__c = novaHora;
                            opp.Snapshot_em_atraso__c = opp.Maquete_em_atraso__c;*/
                        }
                        /*if(Trigger.oldMap.get(opp.Id).Estado_da_maquete__c == 'Pendente'){
                        Long diff = BusinessHours.diff(bh.Id, opp.Inicio_de_pausa_de_maquete__c, System.now());
                        
                        opp.Data_limite_de_maquete__c = BusinessHours.add(bh.Id, opp.Data_limite_de_maquete__c, diff);
                        }*/
                    }
                    
                    //RP 07-11-2018 incrementacao versao enviada
                    List<Schema.FieldSetMember> queryFields = SObjectType.Opportunity.FieldSets.Integration_Fields.getFields(); 
                    sObject oldCon = (sObject)Trigger.oldMap.get(opp.Id);
                    if(opp.Stamp__c != null){
                        for(Schema.FieldSetMember field : queryFields){
                            //system.debug(field.getFieldPath());
                            //system.debug(opp.get(field.getFieldPath()) + ' ' + oldCon.get(field.getFieldPath()));
                            if(opp.get(field.getFieldPath()) != oldCon.get(field.getFieldPath())){
                                if(opp.Versao_enviada__c != null){
                                    opp.Versao_enviada__c = opp.Versao_enviada__c + 1;
                                }
                                else{
                                    opp.Versao_enviada__c = 1;
                                }
                                if(checkRecursive.runOpportunityAfterUpdate) opp.Espera_de_integracao__c = true;
                                break;
                            }
                        }
                    }
                }
                if(!pedidos.isEmpty()) insert pedidos;
                if(!pedidosAtivos.isEmpty()) delete pedidosAtivos;
                
            }
        }else if(Trigger.isDelete){
            if(checkRecursive.runDeleteOpps){
                for(Opportunity opp : Trigger.old){
                    if(opp.Referencia_PHC__c != null){
                        opp.addError(Label.Erro_delete_dossier);
                    }
                }
            }
        }
    }else if(Trigger.isAfter){
        if(Trigger.isUpdate){
            if(checkRecursive.runOpportunityAfterUpdate){
                checkRecursive.runOpportunityAfterUpdate= false;
                List<Schema.FieldSetMember> queryFields = SObjectType.Opportunity.FieldSets.Integration_Fields.getFields(); 
                Set<Id> oppIds = new Set<Id>();
                
                Set<Id> idAmostras = new Set<Id>();//ids dos dossiers de amostra que foram aprovadas para clonar.
                Set<Id> pbIds = new Set<Id>();//ids dos catalogos necessários ao clone de dossiers
                
                //mapa de opps com pedidos ativos
                Map<Id, Opportunity> mapPedidos = new Map<Id, Opportunity>([Select Id, (Select Id,Tempo_de_pausa__c,Numero_de_pausas__c From Pedidos_de_Maquete__r where ativo__c = true) From Opportunity Where Id In :Trigger.new]);
                Map<Id,Pedido_de_Maquete__c> pedidos = new Map<Id,Pedido_de_Maquete__c>();
                for(Id oppId : Trigger.newMap.keySet()){
                    
                    Boolean isChange = false;
                    Opportunity opp = Trigger.newMap.get(oppId);
                    sObject oldCon = (sObject)Trigger.oldMap.get(oppId);
                    if(Trigger.newMap.get(oppId).Stamp__c != null){
                        for(Schema.FieldSetMember field : queryFields){
                            //system.debug(field.getFieldPath());
                            //system.debug(opp.get(field.getFieldPath()) + ' ' + oldCon.get(field.getFieldPath()));
                            if(opp.get(field.getFieldPath()) != oldCon.get(field.getFieldPath())){
                                isChange = true;
                                break;
                            }
                        }
                        
                        if(isChange){
                            oppIds.add(oppId);
                        }
                    }
                    
                    //Dossiers aprovados de amostra
                    if(opp.Amostra__c && opp.Autorizada__c != null && Trigger.oldMap.get(oppId).Autorizada__c == null
                       && opp.Autorizada__c != Trigger.oldMap.get(oppId).Autorizada__c){
                           idAmostras.add(opp.Id);
                           pbIds.add(opp.Pricebook2Id);
                       }
                    
                    //PREENCHER DATA DE ACEITAÇÃO
                    if(opp.Designer__c != null && Trigger.oldMap.get(opp.Id).Designer__c == null){
                        if(mapPedidos.containsKey(opp.Id)){
                            if(!mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.isEmpty()){
                                mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Data_de_Aceitacao__c = system.now();
                                mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Designer__c = opp.Designer__c;
                                pedidos.put(mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Id,
                                            mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0));
                            }
                        }
                    }
                    if(opp.Data_de_envio_de_maquete__c != null && Trigger.oldMap.get(opp.Id).Data_de_envio_de_maquete__c == null){
                        if(mapPedidos.containsKey(opp.Id)){
                            if(!mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.isEmpty()){
                                mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Data_de_envio__c = opp.Data_de_envio_de_maquete__c;
                                mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Designer__c = opp.Designer__c;
                                mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Em_atraso__c = opp.Maquete_em_atraso__c;
                                mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Destinatario__c = opp.Estado_da_maquete__c == 'Pendente' ? 'Comercial' : 'Cliente';
                                pedidos.put(mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Id, mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0));
                            }
                        }
                    }
                    
                    //soma minutos passados em pausa
                    if(opp.Estado_da_maquete__c != Trigger.oldMap.get(opp.Id).Estado_da_Maquete__c){
                        
                        if(Trigger.oldMap.get(opp.Id).Estado_da_Maquete__c == 'Suspenso'){
                            if(mapPedidos.containsKey(opp.Id)){
                                if(!mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.isEmpty()){
                                    mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Numero_de_pausas__c = mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Numero_de_pausas__c != null ? 
                                        mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Numero_de_pausas__c + 1 : 1;
                                    
                                    Long diff = BusinessHours.diff(bh.Id, opp.Inicio_de_pausa_de_maquete__c, System.now());
                                    diff = diff/1000/60;//minutos
                                    if(mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Tempo_de_pausa__c == null)
                                        mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Tempo_de_pausa__c = 0;
                                    mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Tempo_de_pausa__c += Integer.valueOf(diff);
                                    pedidos.put(mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0).Id,
                                                mapPedidos.get(opp.Id).Pedidos_de_Maquete__r.get(0));
                                }
                            }
                        }
                    }
                }
                
                if(!pedidos.isEmpty()) update pedidos.values();
                system.debug(oppIds.isEmpty());
                //@toDo webservice call
                if(!oppIds.isEmpty() && !System.isFuture() && !System.isBatch() && checkRecursive.runRequestOpps){
                    for(Id oppId : oppIds){
                        //***********************************************************************
                        //Keidy - Enviar o mexeLinhas a false se entrar numa dessas condições.
                        //auxMexeLinhas default a true.
                        Boolean auxMexeLinhas = true;
                        Opportunity myNewOpp = Trigger.newMap.get(oppId);
                        Opportunity myOldOpp = Trigger.oldMap.get(oppId);
                        
                        if(myNewOpp.StageName != 'Fechado anulado'){
                            //se muda estado e novo estado 'Aprovada' ou 'Por aceitar'
                            if((myNewOpp.Estado_da_maquete__c != myOldOpp.Estado_da_maquete__c &&
                                (myNewOpp.Estado_da_maquete__c == 'Aprovada' ||
                                 myNewOpp.Estado_da_maquete__c == 'Por aceitar')) ||
                               //ou autorizado muda de vazio para preenchido
                               (myNewOpp.Autorizada__c != null &&
                                myOldOpp.Autorizada__c == null &&
                                myNewOpp.Autorizada__c != myOldOpp.Autorizada__c)){
                                    auxMexeLinhas = false;
                                }
                        }
                    
                        Integrator.actDossier(new Set<Id>{oppId}, auxMexeLinhas);
                        if(Limits.getCallouts()>= Limits.getLimitCallouts()) break;
                    }
                }
                
                if(!idAmostras.isEmpty()){
                    Map<Id, Opportunity> clonesOpp = new Map<Id, Opportunity>();
                    Map<Id, OpportunityLineItem> clonesOlis = new Map<Id, OpportunityLineItem>();
                    Map<String, Pricebookentry> pbes = new Map<String, Pricebookentry>();
                    Map<String, Id> pricebookmap = new Map<String, Id>(); //Mercado / Pricebook2
                    for(PricebookEntry pbe : [Select Id,Pricebook2Id,CurrencyIsoCode From PricebookEntry Where Pricebook2.isStandard = false And ProductCode ='NSAPTI']){
                        pbes.put(pbe.Pricebook2Id+''+pbe.CurrencyIsoCode, pbe);
                    }
                    if(Test.isRunningTest()){
                        pbes.put(Test.getStandardPricebookId() + 'EUR', [Select Id From PricebookEntry Where ProductCode ='NSAPTI' and CurrencyIsoCode = 'EUR' Limit 1]);
                    }
                    for(Pricebook2 pb: [Select id, Mercado__c From Pricebook2 Where isStandard = false]){
                        pricebookMap.put(pb.Mercado__c, pb.Id);
                        if(Test.isRunningTest())pricebookmap.put('1', pb.Id);
                    }
                    List<Schema.FieldSetMember> cloneFields = SObjectType.Opportunity.FieldSets.Clone_Amostras.getFields(); 
                    //clonar dossiers de amostra
                    if(!pbes.isEmpty()){
                        for(Opportunity opp : [Select id, AccountId, Account.ParentId,Account.Parent.Tabela_de_precos__c, Pricebook2Id,CurrencyIsoCode, RecordType.Name, 
                                               (Select Id, Valor_unitario_original__c from OpportunityLineItems) 
                                               from Opportunity Where id in :idAmostras]){
							Opportunity oldOpp = Trigger.newMap.get(opp.Id).clone();
							Opportunity newOpp = new Opportunity();
							if(opp.Account.ParentId == null){
								newOpp.AccountId = opp.AccountId;
								newOpp.CurrencyIsoCode = oldOpp.CurrencyIsoCode;
								newOpp.Pricebook2Id = oldOpp.Pricebook2Id;
							}else{
								newOpp.AccountId = opp.Account.ParentId;
								newOpp.CurrencyIsoCode = ProductManager.mapISOCodes.get(opp.Account.Parent.Tabela_de_precos__c);
								newOpp.Pricebook2Id = pricebookmap.get(opp.Account.Parent.Tabela_de_precos__c);
								system.debug(opp.Account.Parent.Tabela_de_precos__c);
							}
							newOpp.Amostra__c = false;
							newopp.Tipo_de_amostra__c = null;
							newopp.RecordTypeId = oldOpp.RecordTypeId;
							newopp.CloseDate = system.today().addDays(7);
							newopp.Name = oldOpp.Name;
							newOpp.StageName = 'Aberto';
							newOpp.Documento_de_destino__c = 'Factura TER';
							for(Schema.FieldSetMember field : cloneFields){
								newopp.put(field.getFieldPath(), oldOpp.get(field.getFieldPath()));
							}
							
							Decimal totalProds = 0;
							for(OpportunityLineItem oli : opp.OpportunityLineItems){
								if(oli.Valor_unitario_original__c != null)
									totalProds += oli.Valor_unitario_original__c;
							}
                            if(pbes.containsKey(newOpp.Pricebook2Id + newOpp.CurrencyIsoCode)){
                                clonesOpp.put(opp.Id, newOpp);
                                
                                OpportunityLineItem newOli = new OpportunityLineItem();
                                newOli.OpportunityId = newOpp.Id;
                                
                                newOli.PricebookEntryId = pbes.get(newOpp.Pricebook2Id + newOpp.CurrencyIsoCode).Id;
                                newOli.UnitPrice = totalProds;
                                newOli.Preco_unitario__c = totalProds;
                                newOli.Quantity = 1;
                                clonesOlis.put(opp.Id, newOli);                  
                            }
							
                    	}
                    
                        insert clonesOpp.values();
                        
                        for(Id index : clonesOlis.keySet()){
                            OpportunityLineItem oli = clonesOlis.get(index);
                            oli.OpportunityId = clonesOpp.get(index).Id;
                        }
                        
                        
                        if(Test.isRunningTest()){
                            for(Opportunity opp : clonesOpp.values()){
                                opp.Pricebook2Id = Test.getStandardPricebookId();
                            }
                            update clonesOpp.values();
                        }
                        
                        insert clonesOlis.values();
                    }
                }
                
                /******************                     CALCULO DA LINHA DE IMPRESSAO EXTRA (NSIMPEXTRA)                   **************************/
                if(true){
                    
                    //linhas extra por cada oportunidade
                    Map<Id, OpportunityLineItem> impExtras = new Map<Id, OpportunityLineItem>();
                    for(OpportunityLineItem imp : [Select id, OpportunityId From OpportunityLineItem Where OpportunityId In :Trigger.new And ProductCode = 'NSIMPEXTRA']){
                        impExtras.put(imp.OpportunityId, imp);
                    }
                    
                    //pbes do produto extra por cada mercado
                    Map<Id, PricebookEntry> impExtraPbes = new Map<Id, PricebookEntry>();
                    for(PricebookEntry pbe : [Select Id, Pricebook2Id From PricebookEntry Where ProductCode = 'NSIMPEXTRA']){
                        impExtraPbes.put(pbe.Pricebook2Id, pbe);
                    }
                    //dados de classe de testes
                    if(Test.isRunningTest()){
                        try{
                            impExtraPbes.put(Test.getStandardPricebookId(), [Select Id From PricebookEntry Where ProductCode ='NSIMPEXTRA' and CurrencyIsoCode = 'EUR' Limit 1]);
                        }catch(Exception ex){}
                    }
                    
                    //percorre oportunidades para calcular o valor das linhas extra
                    List<OpportunityLineItem> impExtraUpdate = new List<OpportunityLineItem>();
                    List<OpportunityLineItem> impExtraDelete = new List<OpportunityLineItem>();
                    for(Opportunity opp : [Select Id,Pricebook2Id,CurrencyIsoCode, Sem_extra_de_impressao__c,
                                           (Select Id, TotalPrice, isDeleted From opportunityLineItems Where ProductCode != 'NSPORTES' And ProductCode != 'NSPCE' And ProductCode != 'NSPTER' And ProductCode != 'NSIMPEXTRA') 
                                           From Opportunity Where RecordType.DeveloperName = 'Folha_de_Obra' And Id in :Trigger.new]){
                                               //tem que calcular linha extra de impressao
                                               if(!opp.Sem_extra_de_impressao__c){
                                                   system.debug(opp.opportunityLineItems);
                                                   Decimal totalLinhas = 0;
                                                   for(OpportunityLineItem oli : opp.opportunityLineItems){
                                                       //system.debug(oli);
                                                       totalLinhas += oli.TotalPrice;
                                                   }
                                                   boolean needsImpExtra = false;
                                                   Decimal newValue = 0;
                                                   //valida valores
                                                   if(opp.CurrencyIsoCode == 'EUR'){
                                                       needsImpExtra = totalLinhas < 70;
                                                       if(needsImpExtra) newValue = 70 - totalLinhas;
                                                   }else if(opp.CurrencyIsoCode == 'GBP'){
                                                       needsImpExtra = totalLinhas < 60;
                                                       if(needsImpExtra) newValue = 60 - totalLinhas;
                                                   }else if(opp.CurrencyIsoCode == 'PLN'){
                                                       needsImpExtra = totalLinhas < 300;
                                                       if(needsImpExtra) newValue = 300 - totalLinhas;
                                                   }
                                                   if(opp.opportunityLineItems.isEmpty()) needsImpExtra = false;
                                                   //precisa de imp extra
                                                   if(needsImpExtra){
                                                       OpportunityLineItem impExtra;
                                                       //se linha já existe
                                                       if(impExtras.containsKey(opp.Id)){
                                                           impExtra = impExtras.get(opp.Id);
                                                           impExtra.UnitPrice = newValue;
                                                           impExtra.Preco_unitario__c = newValue;
                                                           impExtra.Total_de_customizacao__c = newValue;
                                                       }else{//se linha ainda não existe
                                                           impExtra = new OpportunityLineItem();
                                                           impExtra.OpportunityId = opp.Id;
                                                           impExtra.PricebookEntryId = impExtraPbes.get(opp.Pricebook2Id).Id;
                                                           impExtra.Quantity = 1;
                                                           impExtra.UnitPrice = newValue;
                                                           impExtra.Preco_unitario__c = newValue;
                                                           impExtra.Total_de_customizacao__c = newValue;
                                                           impExtra.Referencia_SKU__c = 'NSIMPEXTRA';
                                                       }
                                                       impExtra.Auxiliar_expedicao__c = 1;
                                                       impExtra.Stock_cativo__c = true;
                                                       impExtraUpdate.add(impExtra);
                                                   }else if(impExtras.containsKey(opp.Id)){
                                                       impExtraDelete.add(impExtras.get(opp.Id));
                                                   }
                                               }
                                               //não calcula linha extra de impressão
                                               else{
                                                   //apaga linha caso exista
                                                   if(impExtras.containsKey(opp.Id)){
                                                       impExtraDelete.add(impExtras.get(opp.Id));
                                                   }
                                               }
                                               
                                           }
                    if(!impExtraUpdate.isEmpty()) upsert impExtraUpdate;
                    if(!impExtraDelete.isEmpty()) delete impExtraDelete;
                }
            }
        }
    }
}