public class c_CustomizacaoDoProduto{

    public Map<String,Product2> listProductC{get;set;}
    public Product2 pd{get;set;}
    
    public c_CustomizacaoDoProduto(ApexPages.StandardController con){ 
        this.pd = [Select ProductCode, Name, Id,Tamanho__c from Product2 where Id=:con.getid()];
        this.listProductC = new Map<String,Product2>();
        for(Product2 product :[Select Id, Referencia_relacionada__c, RecordTypeId, Name, Tecnica__c, Componente_da_impressao__c, Dimensoes_maximas_de_impressao__c, 
                               Cores_de_customizacao__c 
                               from Product2 
                               Where RecordType.DeveloperName= 'Customizacao' AND Referencia_relacionada__c=:pd.ProductCode And Tamanho__c = :pd.Tamanho__c]){
           this.listProductC.put(product.id, product); 
        }
    }
}