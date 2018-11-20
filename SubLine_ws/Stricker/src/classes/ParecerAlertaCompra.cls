public class ParecerAlertaCompra {
    public Integer nClaimsRef {get;set;}
    public Integer nClaimsRefCor {get;set;}
    public List<Element> tiposRef {get;set;}
    public List<Element> tiposRefCor {get;set;}
    public ParecerAlertaCompra(OrderItem claimItem){
        nClaimsRef = 0;
        nClaimsRefCor = 0;
        Map<String, Element> auxTiposRef = new Map<String, Element>();
        Map<String, Element> auxTiposRefCor = new Map<String, Element>();
        for(OrderItem item : [Select id, Referencia_base__c, Referencia_SKU__c, Tipologia__c, Sub_tipologia__c 
                              from OrderItem 
                              Where (Product2Id = :claimItem.Product2Id And CreatedDate > :System.today().addYears(-1)) Or Id = :claimItem.Id]){
            String key = item.Tipologia__c + (item.Sub_tipologia__c != null ? ' - ' + item.Sub_tipologia__c : '');
            if(claimItem.Referencia_base__c == item.Referencia_base__c){
                nClaimsRef++;
                if(!auxTiposRef.containsKey(key)){
                    auxTiposRef.put(key, new Element(key));
                }
                auxTiposRef.put(key, auxTiposRef.get(key).sum());
            }
            if(claimItem.Referencia_SKU__c == item.Referencia_SKU__c){
                nClaimsRefCor++;
                if(!auxTiposRefCor.containsKey(key)){
                    auxTiposRefCor.put(key, new Element(key));
                }
                auxTiposRefCor.put(key, auxTiposRefCor.get(key).sum());
            }
        }
        tiposRef = auxTiposRef.values();
        tiposRef.sort();
        
        tiposRefCor = auxTiposRefCor.values();
        tiposRefCor.sort();
    }
    
    public class Element implements Comparable{
        public Integer nClaims {get;set;}
        public String tipo {get;set;}
        
        public Element(String tipo){
            nClaims = 0;
            this.tipo = tipo;
        }
        
        public Element sum(){
            nClaims++;
            return this;
        }
        
        public Integer compareTo(Object compareTo) {
            Element compareToCust = (Element)compareTo;
            Integer returnValue = 0;
            
            if(this.nClaims > compareToCust.nClaims){
                returnValue = -1;       
            }else if(this.nClaims < compareToCust.nClaims){
                returnValue = 1;   
            }
            return returnValue;
        }
    }
}