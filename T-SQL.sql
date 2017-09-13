---========================================
--This sql file created by  --


---============================================

------- CREATE DATABASE DDL-------------

Create table Book_Author(
AuthorID int IDENTITY NOT NULL,
AuthorName varchar(250) not null,
primary key(AuthorID));

--uniqe key for Book_Author
alter table Book_Author add constraint uniqueAuthorName unique (AuthorName);

  -------------------------------
  -------------------------------


Create table Admin(
AdminID int IDENTITY NOT NULL,
Name varchar(50) not null,
Surname varchar(50) not null,
primary key(AdminID)
)



  -------------------------------
  -------------------------------

Create table Kind(
KindID int IDENTITY NOT NULL,
KindName varchar(50) not null,
primary key(KindID)
)

--uniqe key for Kind
alter table Kind add constraint uniqueKindName unique (KindName);


  -------------------------------
  -------------------------------


Create table Book(
BookID int IDENTITY NOT NULL,
ISBN char(11),
Title varchar(40) not null,
Page int not null,
AuthorID int not null,
Subject varchar(90) not null,
Language varchar(20) not null,
KindID int not null,
BookCount int not null,
AdminID int not null,
primary key(BookID)
)



	 alter table Book add constraint AuthorID     
  foreign key (AuthorID)  references Book_Author (AuthorID);

  
	 alter table Book add constraint AdminID     
  foreign key (AdminID)  references Admin (AdminID);

  	 alter table Book add constraint KindID     
  foreign key (KindID)  references Kind (KindID);


  --unique key for ISBN
  alter table Book add constraint uniqueBookCount unique (ISBN);


--check for Book ; 
--determine BookCount>=1 and Len(ISBN)=11

  alter table Book ADD CONSTRAINT chkBookCount
	CHECK (BookCount>=1 and Len(ISBN)=11)



  
  -------------------------------
  -------------------------------


  
Create table NonBorrow(
Id int IDENTITY NOT NULL,
UserType char(1) NOT NULL, --Student=1, Non-Student=2
Book_Kind char(1) NOT NULL, -- Kind=1, Book=2
Book_Kind_Id int NOT NULL
primary key(Id)
)


--unieqe keys for NonBorrow ; 
alter table NonBorrow add constraint uniqueNonBorrowValues unique (UserType,Book_Kind,Book_Kind_Id);

--check for nonborrow ; 
--recognize UserType Student=1, Non-Student=2
-- recognize Book_Kind Kind=1, Book=2
ALTER TABLE NonBorrow ADD CONSTRAINT chkUsertypeandkind
	CHECK (UserType in ('1', '2') and Book_Kind in ('1', '2') )

  -------------------------------
  -------------------------------


	    Create table BorrowedBook
		(
		BorrowID int IDENTITY NOT NULL,
		BookID int Not Null,
		UserId int not null,
		ReturnDate date not null,
		BorrowDate date not null,
		AdminID int not null,
		RealReturnDate date,
		UserType char(1) not null,--Student=1, Non-Student=2
primary key (BorrowID)

		)

		 alter table BorrowedBook add constraint BookID     
  foreign key (BookID)  references Book (BookID);


   alter table BorrowedBook add constraint AdminID2     
  foreign key (AdminID)  references Admin (AdminID);



  --check for BorrowedBook ; 
--recognize UserType Student=1, Non-Student=2
--ReturnDate>BorrowDate
--BorrowDate=GetDate()

ALTER TABLE BorrowedBook ADD CONSTRAINT chkforBorrowed
	CHECK (UserType in ('1', '2') and ReturnDate>BorrowDate )



  -------------------------------
  -------------------------------


Create table Penaly(
Id int IDENTITY NOT NULL,
BorrowID int  NOT NULL,
AmmountofMoney int Not null,
UserId int not null,
UserType char(1) NOT NULL, --Student=1, Non-Student=2
primary key(Id)
)

		 alter table Penaly add constraint BorrowIDfkforPenalty     
  foreign key (BorrowID)  references BorrowedBook (BorrowID);



--unieqe keys for Penalty ; 
alter table Penaly add constraint uniquePenalyValues unique (BorrowID,UserId,UserType);  



--check for Penalty ; 
--recognize UserType Student=1, Non-Student=2
ALTER TABLE Penaly ADD CONSTRAINT chkforPenalty
	CHECK (UserType in ('1', '2')  )


  -------------------------------
  -------------------------------

  create table NonStudent(
  UserId int IDENTITY NOT NULL,
  Name varchar(50) not null,
  Surname varchar(50) not null,
  primary key(UserId)
  )



  -------------------------------
  -------------------------------
  Create table Faculty(
FacultyID int IDENTITY NOT NULL,
FacultyName varchar(40) not null,
primary key(FacultyID)
)


  ---------------------

  Create table Department(
DepartmentID int IDENTITY NOT NULL,
DeptName varchar(40) not null,
FacultyID int  NOT NULL,
primary key (DepartmentID)
)

  	 
	 alter table Department add constraint FacultyID     
  foreign key (FacultyID)  references Faculty (FacultyID);

    ---------------------

	  Create table Student(
	UserID int IDENTITY NOT NULL,
   DepartmentID int  NOT NULL,
   Name varchar(50) not null,
   Surname varchar(50) not null,
primary key (UserID)
)
	 alter table Student add constraint DepartmentID     
  foreign key (DepartmentID)  references Department (DepartmentID);



  -------------------------------
  -------------------------------




  -------------------------------------------------
-- CREATE DATA DMLs
-------------------------------------------------


--Admin---------
insert into Admin( Name, Surname)
  values ( 'Can','Gündüz');

  insert into Admin( Name, Surname)
  values ( 'Ayþem','Bahar');


  --Author--

  insert into Book_Author(AuthorName)
  values ( 'Nur Akýn');

  insert into Book_Author( AuthorName)
  values ( 'Akif Bilge');

  insert into Book_Author( AuthorName)
  values ( 'Necdet Bilen');

  
  insert into Book_Author( AuthorName)
  values ( 'Nurhayat Ünlü');

    insert into Book_Author(AuthorName)
  values ( 'Cem Ýlgi');


      insert into Book_Author(AuthorName)
  values ( 'John HARRIS');

     insert into Book_Author(AuthorName)
  values ( 'Julia HUNT');


  --Kind
  insert into Kind(KindName)
    values ( 'Technical');


  insert into Kind(KindName)
    values ( 'Novel');


	  insert into Kind(KindName)
    values ( 'Kiþisel Geliþim');


	  insert into Kind(KindName)
    values ( 'Research');

	  insert into Kind(KindName)
    values ( 'History');

		  insert into Kind(KindName)
    values ( 'Literature');

	

	


--Book--

    --Turkish Book :ID ==> 88-
    insert into Book(AdminID,AuthorID,BookCount,ISBN,KindID,Language,Page,Subject,Title)
  values (1, 1, 5 , '88-12345678',1,'Turkish',500,'Hýzlandýrýlmýþ Kalkülüs Soru ve Çözümleri', 'Hýzlandýrýlmýþ Kalkülüs');



  insert into Book(AdminID,AuthorID,BookCount,ISBN,KindID,Language,Page,Subject,Title)
  values (1, 1, 1 , '88-13345678',1,'Turkish',285,'Ýþletmeler Ýçin Maliyet Analizi', 'Maliyet Analizi');



  insert into Book(AdminID,AuthorID,BookCount,ISBN,KindID,Language,Page,Subject,Title)
  values (1, 3, 5 , '88-12345679',1,'Turkish',750,'Bilgisayar Aðlarý, Að Modelleri, Ýletiþim Katmanlarý', 'Bilgisayar Aðlarý');


    insert into Book(AdminID,AuthorID,BookCount,ISBN,KindID,Language,Page,Subject,Title)
  values (1, 7, 5 , '88-12345680',2,'Turkish',375,'Ýletiþim Çaðý', 'Ýletiþim Çaðý');

      insert into Book(AdminID,AuthorID,BookCount,ISBN,KindID,Language,Page,Subject,Title)
  values (1, 7, 3 , '88-12345681',3,'Turkish',150,'Hýzlý Düþünme', 'Hýzlý Düþünme');

        insert into Book(AdminID,AuthorID,BookCount,ISBN,KindID,Language,Page,Subject,Title)
  values (1, 8, 3 , '88-12345682',3,'Turkish',150,'Giriþimcilik', 'Giriþimcilik');
   
  


  --English Book :ID ==> 98-

      insert into Book(AdminID,AuthorID,BookCount,ISBN,KindID,Language,Page,Subject,Title)
  values (2, 8, 5 , '98-12345678',1,'English',500,'Calculus Problem and Solving', 'Accellareted Calculus');



   insert into Book(AdminID,AuthorID,BookCount,ISBN,KindID,Language,Page,Subject,Title)
  values (2, 9, 5 , '98-12345679',4,'English',780,'English Literature and Culture', 'Literature and Culture');




     insert into Book(AdminID,AuthorID,BookCount,ISBN,KindID,Language,Page,Subject,Title)
  values (2, 10, 9 , '98-12345680',5,'English',1050,'The World History', 'The World History');


       insert into Book(AdminID,AuthorID,BookCount,ISBN,KindID,Language,Page,Subject,Title)
  values (2, 2, 1 , '98-12945685',6,'English',675,'Country Literature', 'Country Literature');



      -----------


	   --Non Borrow...


--Student=1, Non-Student=2
--Kind=1, Book=2

--History kind can not be borrow by Student *** We know that the History kind id=5
	        insert into NonBorrow(UserType,Book_Kind,Book_Kind_Id)
			 values (1,1,5);

--History kind can not be borrow by Non-Student  *** We know that the History id=5 at kind table
  insert into NonBorrow(UserType,Book_Kind,Book_Kind_Id)
			 values (2,1,5);


--Technical kind can not be borrow by Non-Student  *** We know that the History id=5 at kind table
  insert into NonBorrow(UserType,Book_Kind,Book_Kind_Id)
			 values (2,1,1);


-- 'Bilgisayar Aglarý' that is book, is not borrowed by Student  *** We know that the 'Bilgisayar Aglarý' id=5 at book table
-- 'Bilgisayar Aglarý' that is book, is  borrowed by Non-Student  
	        insert into NonBorrow(UserType,Book_Kind,Book_Kind_Id)
			 values (1,2,5);



-- 'Literature and Culture' that is book, is not borrowed by Non-Student   *** We know that the 'Bilgisayar Aglarý' id=15 at book table
-- 'Literature and Culture' that is book, is  borrowed by Student 
		 insert into NonBorrow(UserType,Book_Kind,Book_Kind_Id)
			 values (2,2,15);



  --Faculty--
  
   insert into Faculty(FacultyName)
   values('Engineering')

     
   insert into Faculty(FacultyName)
   values('Science and Literature')


      -----------

  --Department--

     insert into Department(DeptName,FacultyID)
   values('Computer',1)


     insert into Department(DeptName,FacultyID)
   values('Industry',1)

   

        insert into Department(DeptName,FacultyID)
   values('History',2)


   
        insert into Department(DeptName,FacultyID)
   values('Literature and Culture',2)

   
      -----------

   -----
   --Student--

   --Computer Engineering
    insert into Student(DepartmentID,Name,Surname)
	values(1,'Arif','Zeki')

	 insert into Student(DepartmentID,Name,Surname)
	values(1,'Timuçin','Eren')

 --Industry Engineering
	 insert into Student(DepartmentID,Name,Surname)
	values(2,'Halis','Gören')


 


	--History
	   insert into Student(DepartmentID,Name,Surname)
	values(3,'Melek','Güven')

	  insert into Student(DepartmentID,Name,Surname)
	values(3,'Ayben','Ova')


	

	--Literature and Culture

insert into Student(DepartmentID,Name,Surname)
	values(4,'Gürbüz','Elibol')
insert into Student(DepartmentID,Name,Surname)
	values(4,'Gül','Aydýn')

		 insert into Student(DepartmentID,Name,Surname)
	values(4,'Hakan','Baskýn')

			  insert into Student(DepartmentID,Name,Surname)
	values(4,'Merve','Beyza')

			 insert into Student(DepartmentID,Name,Surname)
	values(4,'Ayþe','Ovacý')

				  insert into Student(DepartmentID,Name,Surname)
	values(4,'Merve','Karþýyaka')

	
        
		  -----
   --NonStudent--


    insert into NonStudent(Name,Surname)
		values('Can','Karþýyaka')

   insert into NonStudent(Name,Surname)
		values('Merve','Kýnay')
   
 -- add 10 random nonstudent to student table
 declare @cnt int = 0
 declare @fName  varchar(40) = 'FIRST_'
 declare @lName  varchar(40) = 'LAST_'
 while (@cnt < 10) 
 BEGIN
     SET @fName  = @fName  + cast(@cnt as varchar(1))
     SET @lName  = @lName  + cast(@cnt as varchar(1))
   
    
    insert into NonStudent(Name,Surname)
         values (@fName, @lName)
				
     SET @cnt = @cnt  + 1
 Set @fName  = 'FIRST_'
 Set @lName  = 'LAST_'

	
 END





    	
-------------------------------------------------
-- Programability --procedures
-------------------------------------------------
go


create procedure spBorrowBook(@BookId int, @userId int, @AdminId int, @Usertype char(1), @msg int output) 
as
begin


--Kiþinin iade süresi geçip iade etmediði kitap varmý? Var ise yeni kitap almasýný engelle

if exists(select * from  viewNotReturnBooks where viewNotReturnBooks.UserId=@UserID and viewNotReturnBooks.UserType=@UserType and ReturnDate<GetDate())
begin

raiserror('This person borrow lots of book and not return these books before return date',16, 2)
set @msg = 1
return @msg
end



--Kiþinin bu kitabý almaya hakký varmý...
Declare @kindId int =0
Declare @allowresult int=0



--istenilen kitabýn kind id sini buldu...
select @kindId=KindId from Book where Book.BookID=@BookId



--bu usertype ile gelen kiþi bu kitabý alabilir mi?
-- @allowresult =>0 alabilir, =>1 alamaz..

---Aþagýda bu kontrole kind bazýnda baktý... checkBorrow fuction ile
set @allowresult=dbo.checkBorrow(@Usertype,@kindId,1)

if @allowresult>0
begin 
raiserror('This person is not alloved to borrow this kind of book',16, 2)
set @msg = 2
return @msg
end



---Þimdi bu kontrole book bazýnda bakýyor... checkBorrow fuction ile
set @allowresult=dbo.checkBorrow(@Usertype,@BookId,2)

if @allowresult>0
begin 
raiserror('This person is not alloved to borrow this book',16, 2)
set @msg = 3
return @msg
end


--Kiþinin daha önceden bir cezasý varmý...?
--Cezasý varsa iptal et sistem para cezasý olan bir kiþiye ödünç kitap vermez...
if exists(select Penaly.Id from Penaly where UserId=@userId and UserType=@Usertype)
begin
raiserror('This person has penalty. So you cant borrow any book',16,2)
set @msg=4
return @msg
end


--Stored function üzerindeki bütün kontroller yapýldý.


--Borrow date üzerine 15 gün eklle...
Declare @calculateDate date;
set @calculateDate=DATEADD(day,15,GetDate())

Declare @todaydate date;
set @todaydate =GETDATE()

--Ödünç verme iþlemi baþladý...
begin try
begin transaction

insert into BorrowedBook(BookID, UserId, ReturnDate,BorrowDate, AdminID, UserType)
values(@BookId,@userId,@calculateDate,@todaydate,@AdminId,@Usertype)

update Book set BookCount=BookCount-1 where BookID=@BookId

commit transaction
end try

begin catch

if @@TRANCOUNT>0
   begin
   rollback transaction
   declare @errormsg varchar(max)=ERROR_MESSAGE()
   
   raiserror(@errormsg,16,2)

   end
end catch

--procudure end
end







--Stored procedure çaðrýldý...
declare @datetime date=Getdate()
   declare @spBorrowBookresult int

--(@BookId int, @userId int, @AdminId int, @Usertype char(1), @msg int output) 
-- @Usertype =>Student=1, Non-Student=2
Execute spBorrowBook 3,3, 1,'1', @msg=@spBorrowBookresult OUTPUT




-- The non-student whic is id 3; book Id 5 its technical can not borrow. Because technical kind nonborrow for non-student ,
--Execute spBorrowBook 5,3, 1,'2', @msg=@spBorrowBookresult OUTPUT



-- 'Literature and Culture' that is book, is not borrowed by Non-Student   *** We know that the 'Bilgisayar Aglarý' id=15 at book table
--Execute spBorrowBook 15,3, 1,'2', @msg=@spBorrowBookresult OUTPUT
-- 'Literature and Culture' that is book, is  borrowed by Student 
--Execute spBorrowBook 15,3, 1,'1', @msg=@spBorrowBookresult OUTPUT




-------------------
------------------

 declare @spBorrowBookresult int
exec returnBook 3,'1',15, @msg = @spBorrowBookresult OUTPUT
--drop procedure returnBook
go
create procedure returnBook(@userId int,@usertype char(1), @bookId int, @msg int output)
as
begin 

Declare @borrowID int
Declare @returnDate date=null
Declare @borrowDate date =null
Declare @penalty int=0
Declare @penaltyammount int=0

--Kontrol et bu verilen bilgilere ait iade edilmemiþ bir kitap varmý ?

select @returnDate=ReturnDate,@borrowDate=BorrowDate,@borrowID=viewNotReturnBooks.BorrowId from viewNotReturnBooks where viewNotReturnBooks.BookID=@bookId and viewNotReturnBooks.UserId=@userId and viewNotReturnBooks.UserType=@usertype


--Burdaki amaç yukarýdaki select istenilen þart a göre veri geldi mi?
--Geldi ise buralar kesin dolar... bunlar kitap ödünç verilirken doluyordu...
if @returnDate is null and @borrowDate is null
begin
Set @msg=1
raiserror('There isnt any borrow record for your values.',16,2)
return @msg
end

--Kayýt var o zaman devam...

begin try

update BorrowedBook set RealReturnDate=GETDATE()
where UserId=@userId and UserType=@usertype and BookID=@bookId

update Book set BookCount=BookCount+1 where Book.BookID=@bookId

--Kitap geri iade edildi..
set @msg=2


--Ýade süeri geçti ise...
if @returnDate<GETDATE()
begin 
                 
Set @penaltyammount=dbo.sfCalculatePunishment(@usertype,@returndate)

insert into Penaly(BorrowID,AmmountofMoney,UserId,UserType)
values(@borrowID,@penaltyammount,@userId,@usertype)

--Kitap iade edildi ceza var artýk bu kiþi bir daha kitap alamaz...
set @msg=3
return @msg

--if end
end 

commit transaction
end try

--stored end
begin catch


if @@TRANCOUNT>0
  begin

  --Hata algýlandýðýnda iþlemi iptal et...
  set @msg=4 
  return @msg

   rollback transaction
   declare @errormsg varchar(max)=ERROR_MESSAGE()
   
   raiserror(@errormsg,16,2)
  end
end catch

end

go









-------------------------------------------------
-- Programability --functions
-------------------------------------------------
go

--Student or Nonstudent izni varmý bu kitabý veya bu kind a ait kitabý almaya...
create function checkBorrow (@usertype char(1), @Id int, @Book_Kind char(1)) Returns int as
begin
declare @numberofrow int=0

select @numberofrow=count(*) from NonBorrow where NonBorrow.Book_Kind=@Book_Kind and Book_Kind_Id=@Id and UserType=@usertype

return @numberofrow
end
go

--------------
go

-- Verilecek ceza miktarý hesaplanýr öðrenci veya non-öðrenci diye bakýlýp...
create function sfCalculatePunishment(@usertype char(1),@returndate date) Returns int 
as
begin
declare @penaltyammount int=0

-- if usertype =1 => student ; per mont 5 tl ; if usertype =2 => non-student ; per mont 10 tl
select @penaltyammount=case when @usertype='1' then DATEDIFF(day,@returndate,GETDATE())*5
                            when @usertype='2' then DATEDIFF(day,@returndate,GETDATE())*10
							end 

 return @penaltyammount

end

go




-------------------------------------------------
-- Programability --Triger
-------------------------------------------------


create trigger trgBorrowBook on BorrowedBook instead of insert
as
begin
declare @BookId int

declare @usertye char(1)
declare @userId int
declare @ReturnDate date
declare @BorrowDate date
declare @AdminID int

--Insert iþlemi sonucu gelen veriler okundu...
select @usertye=inserted.UserType,@BookId=inserted.BookID,@userId=inserted.UserId,@ReturnDate=inserted.ReturnDate, @BorrowDate=inserted.BorrowDate, @AdminID=inserted.AdminID from inserted








declare @BookCount int



select @BookCount=Book.BookCount from Book where Book.BookID=@BookId

--Eðer kitap sayýsý 1 ise ödünç alma iþlemini gerçekleþtirme...

if @BookCount=1
begin
raiserror('The book count is 1. So you can not borrow this book at now',16,2)
return
end







-- Eðer kiþi ayný kitabý daha önceden ödünç almýþ ve henüz getirmemiþse...iþlemi iptal et.(geri iade süresi henüz geçmemiþ...)
if exists(select * from viewNotReturnBooks where  viewNotReturnBooks.UserType=@usertye and viewNotReturnBooks.UserId=@userId and viewNotReturnBooks.BookID=@BookId)
begin
raiserror('The person borroved this book and not return yet.',16,2)
return
end



--Eðer bütün þartlar saðlandý ise insert e izin ver..

begin try


insert into BorrowedBook(BookID, UserId, ReturnDate,BorrowDate, AdminID, UserType)
values(@BookId,@userId,@ReturnDate,@BorrowDate,@AdminID,@usertye)




end try

begin catch


   begin

   --insert sýrasýnda buradaki foreing key veya deðerleri hatalý olursa(desteklenmeyen key) 
   --veya constaint devreye girerse o hatalarý gösterme bunu yaz...
      
	 print ERROR_MESSAGE()
      raiserror('Unexpected error occered. May your selected bookname or admin type is not support',16,2)
   return
   end


end catch




end








-------------------------------------------------
-- Wievs
-------------------------------------------------

--Bu view amacý ödünç alýnýp geri iade edilmemiþ tüm kitaplarý gönderir( geri iade süresinin geçip geçmediðine bakmaksýzýn...)
create view viewNotReturnBooks (Title, BookID , KindName , Subject , BorrowDate , ReturnDate , UserId , UserType ,BorrowId ) as


select Book.Title,Book.BookID,KindName,Book.Subject,BorrowedBook.BorrowDate,BorrowedBook.ReturnDate,BorrowedBook.UserId,BorrowedBook.UserType,BorrowedBook.BorrowID from BorrowedBook inner join Book on BorrowedBook.BookID=Book.BookID inner join Kind on Kind.KindID=Book.KindID 
where BorrowedBook.RealReturnDate is null

select * from viewNotReturnBooks 

--drop view viewNotReturnBooks



--Bu view amacý her fakültede ödünç alýnan kind lar... Eðer o fakültede ödünç
--alma iþlemi yapmayan öðrenci varsa onu 'NonBorrow' ile göster.... 
create view showBorrowCountaccordingtoFaculty as
select FacultyName,  ISNULL(KindName,'NonBorrow') as Kind, COUNT(*) as Amount from Student inner join Department on Student.DepartmentID=Department.DepartmentID inner join Faculty on Department.FacultyID=Faculty.FacultyID left outer join BorrowedBook on BorrowedBook.UserId=Student.UserID and BorrowedBook.UserType='1' left outer join Book on BorrowedBook.BookID=Book.BookID left outer join Kind on Kind.KindID=Book.KindID group by FacultyName , KindName

select * from showBorrowCountaccordingtoFaculty




--Non Student ve Student için Kesilen Cezalar Ne Kadar....

create view totalPenaltyforStudents as select Sum(AmmountofMoney) as Punishment from Penaly where Penaly.UserType='1'

create view totalPenaltyforNonStudents as  select Sum(AmmountofMoney) as Punishment from  Penaly where Penaly.UserType='2' 



create view userstotalPenal(Kind,TotalPenalty) as

select 'student', isnull(Punishment,0) from totalPenaltyforStudents

union
select 'nonstudent', isnull(Punishment,0) from totalPenaltyforNonStudents

select * from userstotalPenal



-------------------
users and roles
------------------

CREATE LOGIN [testLogin] WITH PASSWORD='test', 
  DEFAULT_DATABASE=[Cen331], DEFAULT_LANGUAGE=[Türkçe], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
CREATE USER [testUser] FOR LOGIN [ercan]

create role testrole;

exec sp_addrolemember  'testrole' , 'testUser' ;

grant exec on spBorrowBook to testrole;

grant exec on returnBook to testrole;

grant select,update,delete,insert   on Books  to testrole;
revoke update,delete,insert on Books from testrole

grant select,update,delete,insert   on Book  to testrole;
grant select,update,delete,insert   on Admin  to testrole;
grant select,update,delete,insert   on Book_Author  to testrole;
grant select,update,delete,insert   on Department  to testrole;
grant select,update,delete,insert   on Faculty  to testrole;
grant select,update,delete,insert   on kind  to testrole;
grant select,update,delete,insert   on NonBorrow  to testrole;
grant select,update,delete,insert   on NonStudent  to testrole;
grant select,update,delete,insert   on Penaly  to testrole;
grant select,update,delete,insert   on Student  to testrole;
grant select,update,delete,insert   on viewNotReturnBooks  to testrole;
grant select,update,delete,insert   on userstotalPenal  to testrole;
grant select,update,delete,insert   on showBorrowCountaccordingtoFaculty  to testrole;
grant select,update,delete,insert   on totalPenaltyforNonStudents  to testrole;
grant select,update,delete,insert   on totalPenaltyforStudents  to testrole;
grant select,update,delete,insert   on userstotalPenal  to testrole;
grant select,update,delete,insert   on viewNotReturnBooks  to testrole;

grant exec   on checkBorrow  to testrole;
grant exec   on sfCalculatePunishment  to testrole;

revoke update,delete,insert on BorrowedBook from testrole
revoke update,delete,insert on Penaly from testrole

 execute as user = 'testUser';

 --rolden çýk...
--revert;