@isTest
public class Test_HoursUtilities {
	static testmethod void HoursUtilities() {
        Test.startTest();
        BusinessHours bh = [SELECT Id, Name, IsActive, IsDefault, SundayStartTime, SundayEndTime, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, 
                            ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime, TimeZoneSidKey, SystemModstamp, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById, LastViewedDate 
                            FROM BusinessHours Where Name = 'PT'];
        HoursUtilities.getTime(System.now(), 1, bh);
        Test.stopTest();
    }
}