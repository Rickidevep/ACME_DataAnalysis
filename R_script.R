attach(ExportedRecords)
install.packages("sqldf")
install.packages("RSQLite")
install.packages("tcltk2")
library("RSQLite")
library("sqldf")
library("tcltk2")

#declear cloumn names 
colnames(ExportedRecords)[colnames(ExportedRecords)=="X1"] <- "Appointment_ID"
colnames(ExportedRecords)[colnames(ExportedRecords)=="X2"] <- "Appointment_StarT"
colnames(ExportedRecords)[colnames(ExportedRecords)=="X3"] <- "Appointment_EndT"
colnames(ExportedRecords)[colnames(ExportedRecords)=="X4"] <- "Provider_ID"
colnames(ExportedRecords)[colnames(ExportedRecords)=="X5"] <- "Customer_ID"
ExportedRecords$Appointment_ID[ExportedRecords$Appointment_ID=="U+FEFF1"] <- 1
sapply(ExportedRecords, typeof)
#Convert date type fro calculate duration of appointments
ExportedRecords$Appointment_StarT <- as.POSIXct(ExportedRecords$Appointment_StarT, format='%Y-%m-%d %H:%M:%S')
ExportedRecords$Appointment_EndT <- as.POSIXct(ExportedRecords$Appointment_EndT, format='%Y-%m-%d %H:%M:%S' )
ExportedRecords$Diff_Appt_Dur <- round((ExportedRecords$Appointment_EndT - ExportedRecords$Appointment_StarT)/3600)

#validate if appoinment IDs are unique identifier
sqldf("select count(Appointment_ID) from ExportedRecords")
sqldf("select count(distinct Appointment_ID) from ExportedRecords")

#Assume in the dataset Appointment ID should be unique and each provider need to have at least 1 customer.
#Provide ID and Customer ID should not be empty. I eliminate the data out of this range. 
#Store data in table called version1
write.table(sqldf("select Appointment_ID,Appointment_StarT, Appointment_EndT,Provider_ID,Customer_ID, Diff_Appt_Dur, count(Customer_ID)
      from ExportedRecords where Provider_ID is not null and Customer_ID is not null
      group by Provider_ID having count(Customer_ID>=1)",method = "name__class"),"D:/Version1.csv",sep=",")

#Convert date data type from UNIX TO GMT
Version1$Appointment_StarT <- as.POSIXct(as.numeric(Version1$Appointment_StarT), origin = '1970-01-01', tz = 'GMT')
Version1$Appointment_EndT <- as.POSIXct(as.numeric(Version1$Appointment_EndT), origin = '1970-01-01', tz = 'GMT')

#Summary data
summary(Version1)


#Look for all Providers which average appointment duration above average appointment duration of all appointment 
sqldf("select Provider_ID,avg(Appt_Duration) from Version1 group by Provider_ID having avg(Appt_Duration) >= 4.78")

#Compare number ofs customer and number of providers
sqldf("select count(distinct Provider_ID) from ExportedRecords ")
sqldf("select count(distinct Customer_ID) from ExportedRecords ")



#Cast time data 
Version1$Start_Hours <- format(as.POSIXct(strptime(Version1$Appointment_StarT,'%Y-%m-%d %H:%M:%S',tz="")) ,format = '%H:%M:%S')
Version1$End_Hours <- format(as.POSIXct(strptime(Version1$Appointment_EndT,'%Y-%m-%d %H:%M:%S',tz="")) ,format = '%H:%M:%S')

#set constraint of the data because we are look for normal business hours 8:00am -17:00pm
write.table(sqldf("select Appointment_ID, Appt_Duration,Provider_ID, Customer_ID from Version1 where Start_Hours between '08:00:00' and '17:00:00'", method = "name__class"),"D:/Version3.csv",sep=",")
sqldf("select Appointment_StarT,Customer_ID from ExportedRecords where Customer_ID is not null")
sqldf("select avg(Appt_Duration) from Version1 where Start_Hours between '08:00:00' and '17:00:00'", method = "name__class")


hist(Version3$Appt_Duration)
summary(Version3)
quantile(Version3$Appt_Duration)
table(Version3$Appt_Duration)

hist(Version1$Appt_Duration)
summary(Version1)
quantile(Version1$Appt_Duration)
table(Version1$Appt_Duration)

#Find out if a customer has more than one provider
sqldf("select count(Provider_ID), Customer_ID from ExportedRecords where Customer_ID is not null and Provider_ID is not null group by Customer_ID ")
