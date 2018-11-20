@isTest
public class Test_DeleteProds {

    testmethod static void test1(){
        b_DeleteProds batch = new b_DeleteProds();
        DAtabase.executeBatch(batch);
        
        List<Product2> prods = new List<Product2>();
        batch.execute(null, prods);
    }
}