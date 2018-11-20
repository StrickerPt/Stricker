public class Utils {

    public static String currencySymbol(String iso) { 
        String symbol = iso;  
        if (iso=='USD') { symbol='$'; } 
        else if (iso=='PLN') { symbol='zl'; }
        else if (iso=='GBP') { symbol='£'; } 
        else if (iso=='EUR') { symbol='€'; }
        return symbol; 
    }
    
    public static String getDossTypeName(Integer ndos){
        String name = '';  
        if (ndos==2) { name=Label.Nota_de_encomenda; } 
        else if (ndos==32) { name=Label.Folha_de_obra; }
        else if (ndos==40) { name=Label.Folha_de_Obra_de_Importacao; } 
        return name; 
    }
    
    public static String getDossTypeShortName(Integer ndos){
        String name = '';  
        if (ndos==2) { name='NE'; } 
        else if (ndos==32) { name='FO'; }
        else if (ndos==40) { name='FOI'; } 
        return name; 
    }
    
    public static Decimal calculaPreco(Account acc, PricebookEntry pbe, Decimal quant, Map<String, Preco_por_cliente__c> precos){
        Decimal result = 0;
        if(precos.containsKey(pbe.Product2Id)){
            result = precos.get(pbe.Product2Id).Valor__c;
        }else if(acc.Escalao_Hidea__c != null && acc.Escalao_Hidea__c != '1'){
            result = (Decimal)pbe.get('Preco_'+acc.Escalao_Hidea__c+'__c');
        }else{
            Integer i = 1;
            while(i <= 10){
                if(((Decimal) pbe.get('Minimo_'+i+'__c')) <= quant && ((Decimal) pbe.get('Maximo_'+i+'__c')) >= quant){
                    result = (Decimal)pbe.get('Preco_'+i+'__c');
                    break;
                }
                i++;
            }
        }
        return result;
    }
    
    public static Map<String, Preco_por_cliente__c> getMapaPrecos(String no){
        Map<String,Preco_por_cliente__c> map_precos = new Map<String,Preco_por_cliente__c>();
        for(Preco_por_cliente__c p : [select Produto__c,Valor__c from Preco_por_cliente__c where Cliente__r.Numero_de_cliente__c =:no 
                                      And ((Data_de_inicio__c <= :System.today() And Data_de_fim__c >= :System.today())
                                           OR (Data_de_inicio__c <= :System.today() And Data_de_Fim__c = null)
                                           OR (Data_de_inicio__c = null And Data_de_fim__c >= :System.today())
                                           OR (Data_de_inicio__c = null And Data_de_fim__c = null))]){
            map_precos.put(p.Produto__c, p);
        }
        
        return map_precos;
    }
    
    public static String buildChaveCustomizacao(Product2 cust){
        String separador = ';';
        /*if(cust.Tabela_de_customizacoes__c == '4A'){
            if(cust.Altura_maxima__c == 60 && cust.Comprimento_maximo__c == 95){
                cust.Tabela_de_customizacoes__c = '4A-2';
            }else if(cust.Altura_maxima__c == 140 && cust.Comprimento_maximo__c == 95){
                cust.Tabela_de_customizacoes__c = '4A-3';
            }else if(cust.Altura_maxima__c == 200 && cust.Comprimento_maximo__c == 140){
                cust.Tabela_de_customizacoes__c = '4A-4';
            }else if(cust.Altura_maxima__c == 200 && cust.Comprimento_maximo__c == 280){
                cust.Tabela_de_customizacoes__c = '4A-5';
            }
        }else if(cust.Tabela_de_customizacoes__c == '5'){
            cust.Cores_de_customizacao__c = '1';
            cust.Tabela_de_customizacoes__c = cust.Tabela_de_customizacoes__c + '-' + cust.Cores_de_customizacao__c;
        }*/
        return cust.Referencia_relacionada__c + (cust.Tamanho__c != null ? '-' + cust.Tamanho__c : '') + separador//ref
            + cust.Tabela_de_customizacoes__c + separador
            + cust.Id_Componente__c + separador
            + cust.Id_Local__c + separador
            + cust.Cores_de_customizacao__c;
    }
    
    public static Product2 buildProduto(String refRel, String tabCust, String comp, String local, String colCust, Decimal alt, Decimal compri){
        
        return new Product2(Referencia_relacionada__c = refRel, 
                            Tabela_de_customizacoes__c = tabCust,
                            Id_Componente__c = comp.isNumeric() ? Integer.valueOf(comp) : 0, 
                            Id_Local__c = local.isNumeric() ? Integer.valueOf(local) : 0, 
                            Cores_de_customizacao__c = colCust, 
                            Altura_maxima__c = alt, 
                            Comprimento_maximo__c = compri);
    }
    
    public static Product2 buildProduto(String refRel, String tabCust, String comp, String local, String colCust){
        
        return new Product2(Referencia_relacionada__c = refRel, 
                            Tabela_de_customizacoes__c = tabCust, 
                            Id_Componente__c = comp.isNumeric() ? Integer.valueOf(comp) : 0, 
                            Id_Local__c = local.isNumeric() ? Integer.valueOf(local) : 0, 
                            Cores_de_customizacao__c = colCust);
    }
    
    public static String getObjectFieldLabel(String obj, String field){
        return Schema.getGlobalDescribe().get(obj).getDescribe().fields.getMap().get(field).getDescribe().getLabel();
    }
}