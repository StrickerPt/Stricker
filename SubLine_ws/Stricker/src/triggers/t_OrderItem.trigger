trigger t_OrderItem on OrderItem (before insert, after insert, before update, after update) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            Set<String> productRefs = new Set<String>();
            Set<String> productRefsSKU = new Set<String>();
            Set<Id> caseIds = new Set<Id>();
            
            for(OrderItem item :Trigger.new){
                if(!item.Referencia_SKU__c.contains('NS')){
                    system.debug(item.Referencia_SKU__c);
                    productRefs.add(item.Referencia_SKU__c.split('\\.')[0]);
                    productRefsSKU.add(item.Referencia_SKU__c);
                }
                caseIds.add(item.Reclamacao__c);
            }
            Map<String, Product2> products = new Map<String, Product2>();
            
            for(Product2 prod : [Select Id,ProductCode, Tamanho__c, Em_controlo_de_qualidade__c  From Product2 Where ProductCode In :productRefs]){
                products.put(prod.ProductCode + (prod.Tamanho__c != null ? '-' + prod.Tamanho__c : ''), prod);
            }
            
            Map<Id, Case> cases = new Map<Id, Case>([Select Id,AccountId From Case Where Id In :caseIds]);
            Set<Id> accsId = new Set<Id>();
            for(Case caso : cases.values()){
                accsId.add(caso.AccountId);
            }
            
            Set<String> addeditems = new Set<String>();
            List<OpportunityLineItem> items = [Select Id, OpportunityId, ProductCode ,Tamanho__c,opportunity.AccountId, Opportunity.Amostra__c, Opportunity.CreatedDate
                                               From OpportunityLineItem 
                                               Where Product2Id In :products.values() 
                                               And Opportunity.AccountId In :accsId ];
            system.debug(items);
            for(OpportunityLineItem item : items){
                String firstKey = item.ProductCode + (item.Tamanho__c != null ? '-' + item.Tamanho__c : '');
                if(!addeditems.contains(firstKey + item.OpportunityId)){
                    for(OrderItem ordItem : Trigger.new){
                        if(firstKey == (ordItem.Referencia_SKU__c.split('\\.')[0] + (ordItem.Tamanho__c != null ? '-' + ordItem.Tamanho__c : '')) && !addeditems.contains(firstKey + ordItem.Reclamacao__c + item.OpportunityId)){
                            if(item.opportunity.AccountId == cases.get(ordItem.Reclamacao__c).AccountId){
                                //VIII: NUMERO DE DOSSIERS DESTE CLIENTE QUE CONTEM O ARTIGO PRESENTE NESTA RECLAMAÇÃO NOS ULTIMOS 2 MESES
                                if( item.Opportunity.CreatedDate > System.today().addMonths(-2)){
                                    ordItem.N_dossiers_cliente_mesmo_artigo__c = ordItem.N_dossiers_cliente_mesmo_artigo__c != null ? ordItem.N_dossiers_cliente_mesmo_artigo__c + 1 : 1;
                                    addeditems.add(firstKey + item.OpportunityId);
                                    addeditems.add(firstKey + ordItem.Reclamacao__c + item.OpportunityId);
                                }
                                //X: NUMERO DE DOSSIERS DE AMOSTRA DESTE ARTIGO
                                if(item.Opportunity.Amostra__c){
                                    ordItem.N_dossiers_amostra_cliente_mesmo_artigo__c = ordItem.N_dossiers_amostra_cliente_mesmo_artigo__c != null ? ordItem.N_dossiers_amostra_cliente_mesmo_artigo__c + 1 : 1;
                                }
                                
                                
                            }
                        }
                    }
                }
            }
            
            //MAPA PARA GUARDAR O NUMERO DE VEZES QUE A REFERENCIA BASE ESTÁ PRESENTE EM RECLAMAÇÕES NOS ULTIMOS 3 MESES
            Map<String, Integer> existingItemsRef = new Map<String, Integer>();
            for(OrderItem existItem : [Select Id, Referencia_base__c from OrderItem Where Referencia_base__c In :productRefs And CreatedDate > :System.today().addMonths(-3)]){
                if(!existingItemsRef.containsKey(existItem.Referencia_base__c)){
                    existingItemsRef.put(existItem.Referencia_base__c, 0);
                }
                existingItemsRef.put(existItem.Referencia_base__c, existingItemsRef.get(existItem.Referencia_base__c) + 1);
            }
            
            //MAPA PARA GUARDAR O NUMERO DE VEZES QUE A REFERENCIA COMPLETA ESTÁ PRESENTE EM RECLAMAÇÕES NOS ULTIMOS 3 MESES
            Map<String, Integer> existingItemsSku = new Map<String, Integer>();
            for(OrderItem existItem : [Select id, Referencia_Sku__c from OrderItem Where Referencia_Sku__c In :productRefsSKU And CreatedDate > :System.today().addMonths(-3)]){
                if(!existingItemsSku.containsKey(existItem.Referencia_Sku__c)){
                    existingItemsSku.put(existItem.Referencia_Sku__c, 0);
                }
                existingItemsSku.put(existItem.Referencia_Sku__c, existingItemsSku.get(existItem.Referencia_Sku__c) + 1);
            }
            
            for(OrderItem ordItem : Trigger.new){
                
                //XI: PRODUTO EM CONTROLO DE QUALIDADE
                if(products.containsKey(ordItem.Referencia_SKU__c.split('\\.')[0] + (ordItem.Tamanho__c != null ? '-' + ordItem.Tamanho__c : ''))){
                    Product2 p = products.get(ordItem.Referencia_SKU__c.split('\\.')[0] + (ordItem.Tamanho__c != null ? '-' + ordItem.Tamanho__c : ''));
                    if(p.Em_controlo_de_qualidade__c){
                        ordItem.Produto_bloqueado_Controlo_de_Qualidade__c = true;
                    }
                }
                
                //Referencia base reclamada nos ultimos 3 meses
                if(existingItemsRef.containsKey(ordItem.Referencia_SKU__c.split('\\.')[0])){
                    ordItem.N_de_reclamacoes_produto_base__c = existingItemsRef.get(ordItem.Referencia_SKU__c.split('\\.')[0]);
                    ordItem.Produto_base_reclamado_3_vezes__c = existingItemsRef.get(ordItem.Referencia_SKU__c.split('\\.')[0]) > 3;
                }
                if(existingItemsSku.containsKey(ordItem.Referencia_SKU__c)){
                    ordItem.N_de_reclamacoes_produto_completo__c = existingItemsSku.get(ordItem.Referencia_SKU__c);
                    ordItem.Produto_completo_reclamado_3_vezes__c = existingItemsSku.get(ordItem.Referencia_SKU__c) > 3;
                }
            }
            
            
        }else if(Trigger.isUpdate){
            Id siteProfile = [Select Id From Profile Where Name = 'Paul Stricker Perfil'].Id;
            Map<Id, Case> myCases = new Map<Id,Case>([Select id,Data_de_primeira_analise_do_comercial__c 
                                                      From Case 
                                                      Where Id In (Select Reclamacao__c From OrderItem Where Id In :Trigger.new)]);
            Map<Id, Case> updateCases = new Map<Id,Case>();
            for(OrderItem item : trigger.new){
                if(item.Tipologia__c != Trigger.oldMap.get(item.Id).Tipologia__c && item.Tipologia_sugerida_comercial__c == null && UserInfo.getProfileId() != siteProfile){
                    item.Tipologia_sugerida_comercial__c = item.Tipologia__c;
                }
                
                if(myCases.containsKey(item.Reclamacao__c) &&
                   myCases.get(item.Reclamacao__c).Data_de_primeira_analise_do_comercial__c == null &&
                   UserInfo.getProfileId() != siteProfile){
                       updateCases.put(item.Reclamacao__c, new Case(Id = item.Reclamacao__c, Data_de_primeira_analise_do_comercial__c = System.now()));
                   }
            }
            update updateCases.values();
        }
    } else if(Trigger.isAfter){
        if(checkRecursive.runOrderItem && checkRecursive.runCase){
            checkRecursive.runOrderItem = false;
            if(Trigger.isInsert){
                b_UpdatePrecosTransp batch = new b_UpdatePrecosTransp(Trigger.newMap.keySet());
                Database.executeBatch(batch, 5);
            }else if(Trigger.isUpdate){
                Set<Id> caseIds = new Set<Id>();
                
                for(OrderItem item : Trigger.new){
                    caseIds.add(item.Reclamacao__c);
                }
                if(!caseIds.isEmpty() && !System.isFuture() && !System.isBatch()){
                    for(Id caseId : caseIds){
                        IntegratorClaims.updateClaim(caseId);
                    }
                }
            }
        }
        
    }
}