public class HoursUtilities {

    public static Datetime getTime(Datetime startDate, Decimal numberOfDays, BusinessHours bh){
        Long dt = 0;
        for(Integer i = 0; i < numberOfDays; i++){
            Date thisWeekDay = system.today().addDays(i);
            if(BusinessHours.nextStartDate(bh.Id, thisWeekDay).date() == thisWeekDay){
                Datetime auxData = BusinessHours.nextStartDate(bh.Id, thisWeekDay);
                
                Time endWeekDay = (Time) bh.get(calculateDayOfDate(thisWeekDay)+'EndTime');
                Datetime endDate = Datetime.newInstance(thisWeekDay, endWeekDay);
                
                dt += endDate.getTime() - auxData.getTime();
            }else{
                numberOfDays++;
            }
        }
        Datetime targetDate = BusinessHours.add(bh.Id, startDate, dt);
        return targetDate;
    }
    
    public static String calculateDayOfDate(Date thisDate)
    {
        Date startDate = date.newInstance(0001, 1, 1);
        List<String> listDay = new List<String>{'Saturday' , 'Sunday' , 'Monday' , 'Tuesday' , 'Wednesday' , 'Thursday' , 'Friday'};
            Date selectedDate = thisDate;
        Integer remainder = Math.mod(startDate.daysBetween(selectedDate) , 7);
        return listDay.get(remainder);
    }
}