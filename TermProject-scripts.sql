USE [Cen331]
GO
/****** Object:  User [testUser]    Script Date: 24.12.2014 20:06:34 ******/
CREATE USER [testUser] FOR LOGIN [testLogin] WITH DEFAULT_SCHEMA=[dbo]
GO
/****** Object:  DatabaseRole [testrole]    Script Date: 24.12.2014 20:06:34 ******/
CREATE ROLE [testrole]
GO
ALTER ROLE [testrole] ADD MEMBER [testUser]
GO
/****** Object:  StoredProcedure [dbo].[returnBook]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[returnBook](@userId int,@usertype char(1), @bookId int, @msg int output)
as
begin

Declare @borrowID int
Declare @returnDate date=null
Declare @borrowDate date =null
Declare @penalty int=0
Declare @penaltyammount int=0

--Kontrol et bu verilen bilgilere ait iade edilmemiş bir kitap varmı ?

select @returnDate=ReturnDate,@borrowDate=BorrowDate,@borrowID=viewNotReturnBooks.BorrowId from viewNotReturnBooks where viewNotReturnBooks.BookID=@bookId and viewNotReturnBooks.UserId=@userId and viewNotReturnBooks.UserType=@usertype


--Burdaki amaç yukarıdaki select istenilen şart a göre veri geldi mi?
--Geldi ise buralar kesin dolar... bunlar kitap ödünç verilirken doluyordu...
if @returnDate is null and @borrowDate is null
begin
Set @msg=1
raiserror('There isnt any borrow record for your values.',16,2)
return @msg
end

--Kayıt var o zaman devam...

begin try

update BorrowedBook set RealReturnDate=GETDATE()
where UserId=@userId and UserType=@usertype and BookID=@bookId

update Book set BookCount=BookCount+1 where Book.BookID=@bookId

--Kitap geri iade edildi..
set @msg=2


--İade süeri geçti ise...
if @returnDate<GETDATE()
begin
                 
Set @penaltyammount=dbo.sfCalculatePunishment(@usertype,@returndate)

insert into Penaly(BorrowID,AmmountofMoney,UserId,UserType)
values(@borrowID,@penaltyammount,@userId,@usertype)

--Kitap iade edildi ceza var artık bu kişi bir daha kitap alamaz...
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

  --Hata algılandığında işlemi iptal et...
  set @msg=4 
  return @msg

   rollback transaction
   declare @errormsg varchar(max)=ERROR_MESSAGE()
   
   raiserror(@errormsg,16,2)
  end
end catch

end


GO
/****** Object:  StoredProcedure [dbo].[spBorrowBook]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create procedure [dbo].[spBorrowBook](@BookId int, @userId int, @AdminId int, @Usertype char(1), @msg int output) 
as
begin


--Kişinin iade süresi geçip iade etmediği kitap varmı? Var ise yeni kitap almasını engelle

if exists(select * from  viewNotReturnBooks where viewNotReturnBooks.UserId=@UserID and viewNotReturnBooks.UserType=@UserType and ReturnDate<GetDate())
begin

raiserror('This person borrow lots of book and not return these books before return date',16, 2)
set @msg = 1
return @msg
end



--Kişinin bu kitabı almaya hakkı varmı...
Declare @kindId int =0
Declare @allowresult int=0



--istenilen kitabın kind id sini buldu...
select @kindId=KindId from Book where Book.BookID=@BookId



--bu usertype ile gelen kişi bu kitabı alabilir mi?
-- @allowresult =>0 alabilir, =>1 alamaz..

---Aşagıda bu kontrole kind bazında baktı... checkBorrow fuction ile
set @allowresult=dbo.checkBorrow(@Usertype,@kindId,1)

if @allowresult>0
begin 
raiserror('This person is not alloved to borrow this kind of book',16, 2)
set @msg = 2
return @msg
end



---Şimdi bu kontrole book bazında bakıyor... checkBorrow fuction ile
set @allowresult=dbo.checkBorrow(@Usertype,@BookId,2)

if @allowresult>0
begin 
raiserror('This person is not alloved to borrow this book',16, 2)
set @msg = 3
return @msg
end


--Kişinin daha önceden bir cezası varmı...?
--Cezası varsa iptal et sistem para cezası olan bir kişiye ödünç kitap vermez...
if exists(select Penaly.Id from Penaly where UserId=@userId and UserType=@Usertype)
begin
raiserror('This person has penalty. So you cant borrow any book',16,2)
set @msg=4
return @msg
end


--Stored function üzerindeki bütün kontroller yapıldı.


--Borrow date üzerine 15 gün eklle...
Declare @calculateDate date;
set @calculateDate=DATEADD(day,15,GetDate())

Declare @todaydate date;
set @todaydate =GETDATE()

--Ödünç verme işlemi başladı...
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

GO
/****** Object:  UserDefinedFunction [dbo].[checkBorrow]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[checkBorrow] (@usertype char(1), @Id int, @Book_Kind char(1)) Returns int as
begin
declare @numberofrow int=0

select @numberofrow=count(*) from NonBorrow where NonBorrow.Book_Kind=@Book_Kind and Book_Kind_Id=@Id and UserType=@usertype

return @numberofrow
end

GO
/****** Object:  UserDefinedFunction [dbo].[sfCalculatePunishment]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Verilecek ceza miktarı hesaplanır öğrenci veya non-öğrenci diye bakılıp...
create function [dbo].[sfCalculatePunishment](@usertype char(1),@returndate date) Returns int 
as
begin
declare @penaltyammount int=0

-- if usertype =1 => student ; per mont 5 tl ; if usertype =2 => non-student ; per mont 10 tl
select @penaltyammount=case when @usertype='1' then DATEDIFF(day,@returndate,GETDATE())*5
                            when @usertype='2' then DATEDIFF(day,@returndate,GETDATE())*10
							end 

 return @penaltyammount

end


GO
/****** Object:  UserDefinedFunction [dbo].[sfNotReturnBooks]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[sfNotReturnBooks]()
Returns @retNotReturn Table
(Title varchar(40), BookID int, KindName varchar(50), Subject varchar(50), BorrowDate date, ReturnDate Date, UserId int, UserType char(1), BorrowId int)
As
Begin
insert @retNotReturn(Title,BookID,KindName,Subject,BorrowDate,ReturnDate,UserId,UserType,BorrowId)

select Book.Title,Book.BookID,KindName,Book.Subject,BorrowedBook.BorrowDate,BorrowedBook.ReturnDate,BorrowedBook.UserId,BorrowedBook.UserType,BorrowedBook.BorrowID from BorrowedBook inner join Book on BorrowedBook.BookID=Book.BookID inner join Kind on Kind.KindID=Book.KindID 
where BorrowedBook.RealReturnDate is null


return
End
GO
/****** Object:  Table [dbo].[Admin]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Admin](
	[AdminID] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Surname] [varchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AdminID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Book]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Book](
	[BookID] [int] IDENTITY(1,1) NOT NULL,
	[ISBN] [char](11) NULL,
	[Title] [varchar](40) NOT NULL,
	[Page] [int] NOT NULL,
	[AuthorID] [int] NOT NULL,
	[Subject] [varchar](90) NOT NULL,
	[Language] [varchar](20) NOT NULL,
	[KindID] [int] NOT NULL,
	[BookCount] [int] NOT NULL,
	[AdminID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[BookID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uniqueBookCount] UNIQUE NONCLUSTERED 
(
	[ISBN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Book_Author]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Book_Author](
	[AuthorID] [int] IDENTITY(1,1) NOT NULL,
	[AuthorName] [varchar](250) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AuthorID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uniqueAuthorName] UNIQUE NONCLUSTERED 
(
	[AuthorName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[BorrowedBook]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[BorrowedBook](
	[BorrowID] [int] IDENTITY(1,1) NOT NULL,
	[BookID] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[ReturnDate] [date] NOT NULL,
	[BorrowDate] [date] NOT NULL,
	[AdminID] [int] NOT NULL,
	[RealReturnDate] [date] NULL,
	[UserType] [char](1) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[BorrowID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Department]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Department](
	[DepartmentID] [int] IDENTITY(1,1) NOT NULL,
	[DeptName] [varchar](40) NOT NULL,
	[FacultyID] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DepartmentID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Faculty]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Faculty](
	[FacultyID] [int] IDENTITY(1,1) NOT NULL,
	[FacultyName] [varchar](40) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[FacultyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Kind]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Kind](
	[KindID] [int] IDENTITY(1,1) NOT NULL,
	[KindName] [varchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[KindID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uniqueKindName] UNIQUE NONCLUSTERED 
(
	[KindName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[NonBorrow]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[NonBorrow](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserType] [char](1) NOT NULL,
	[Book_Kind] [char](1) NOT NULL,
	[Book_Kind_Id] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uniqueNonBorrowValues] UNIQUE NONCLUSTERED 
(
	[UserType] ASC,
	[Book_Kind] ASC,
	[Book_Kind_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[NonStudent]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[NonStudent](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Surname] [varchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Penaly]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Penaly](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[BorrowID] [int] NOT NULL,
	[AmmountofMoney] [int] NOT NULL,
	[UserId] [int] NOT NULL,
	[UserType] [char](1) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [uniquePenalyValues] UNIQUE NONCLUSTERED 
(
	[BorrowID] ASC,
	[UserId] ASC,
	[UserType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Student]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Student](
	[UserID] [int] IDENTITY(1,1) NOT NULL,
	[DepartmentID] [int] NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[Surname] [varchar](50) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[totalPenaltyforStudents]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[totalPenaltyforStudents] as select Sum(AmmountofMoney) as Punishment from Penaly where Penaly.UserType='1'
GO
/****** Object:  View [dbo].[totalPenaltyforNonStudents]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[totalPenaltyforNonStudents] as  select Sum(AmmountofMoney) as Punishment from  Penaly where Penaly.UserType='2' 
GO
/****** Object:  View [dbo].[userstotalPenal]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[userstotalPenal](Kind,TotalPenalty) as

select 'student', isnull(Punishment,0) from totalPenaltyforStudents

union
select 'nonstudent', isnull(Punishment,0) from totalPenaltyforNonStudents
GO
/****** Object:  View [dbo].[showBorrowCountaccordingtoFaculty]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[showBorrowCountaccordingtoFaculty] as
select FacultyName,  ISNULL(KindName,'NonBorrow') as Kind, COUNT(*) as Amount from Student inner join Department on Student.DepartmentID=Department.DepartmentID inner join Faculty on Department.FacultyID=Faculty.FacultyID left outer join BorrowedBook on BorrowedBook.UserId=Student.UserID and BorrowedBook.UserType='1' left outer join Book on BorrowedBook.BookID=Book.BookID left outer join Kind on Kind.KindID=Book.KindID group by FacultyName , KindName

GO
/****** Object:  View [dbo].[viewNotReturnBooks]    Script Date: 24.12.2014 20:06:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[viewNotReturnBooks] (Title, BookID , KindName , Subject , BorrowDate , ReturnDate , UserId , UserType ,BorrowId ) as


select Book.Title,Book.BookID,KindName,Book.Subject,BorrowedBook.BorrowDate,BorrowedBook.ReturnDate,BorrowedBook.UserId,BorrowedBook.UserType,BorrowedBook.BorrowID from BorrowedBook inner join Book on BorrowedBook.BookID=Book.BookID inner join Kind on Kind.KindID=Book.KindID 
where BorrowedBook.RealReturnDate is null

GO
ALTER TABLE [dbo].[Book]  WITH CHECK ADD  CONSTRAINT [AdminID] FOREIGN KEY([AdminID])
REFERENCES [dbo].[Admin] ([AdminID])
GO
ALTER TABLE [dbo].[Book] CHECK CONSTRAINT [AdminID]
GO
ALTER TABLE [dbo].[Book]  WITH CHECK ADD  CONSTRAINT [AuthorID] FOREIGN KEY([AuthorID])
REFERENCES [dbo].[Book_Author] ([AuthorID])
GO
ALTER TABLE [dbo].[Book] CHECK CONSTRAINT [AuthorID]
GO
ALTER TABLE [dbo].[Book]  WITH CHECK ADD  CONSTRAINT [KindID] FOREIGN KEY([KindID])
REFERENCES [dbo].[Kind] ([KindID])
GO
ALTER TABLE [dbo].[Book] CHECK CONSTRAINT [KindID]
GO
ALTER TABLE [dbo].[BorrowedBook]  WITH CHECK ADD  CONSTRAINT [AdminID2] FOREIGN KEY([AdminID])
REFERENCES [dbo].[Admin] ([AdminID])
GO
ALTER TABLE [dbo].[BorrowedBook] CHECK CONSTRAINT [AdminID2]
GO
ALTER TABLE [dbo].[BorrowedBook]  WITH CHECK ADD  CONSTRAINT [BookID] FOREIGN KEY([BookID])
REFERENCES [dbo].[Book] ([BookID])
GO
ALTER TABLE [dbo].[BorrowedBook] CHECK CONSTRAINT [BookID]
GO
ALTER TABLE [dbo].[Department]  WITH CHECK ADD  CONSTRAINT [FacultyID] FOREIGN KEY([FacultyID])
REFERENCES [dbo].[Faculty] ([FacultyID])
GO
ALTER TABLE [dbo].[Department] CHECK CONSTRAINT [FacultyID]
GO
ALTER TABLE [dbo].[Penaly]  WITH CHECK ADD  CONSTRAINT [BorrowIDfkforPenalty] FOREIGN KEY([BorrowID])
REFERENCES [dbo].[BorrowedBook] ([BorrowID])
GO
ALTER TABLE [dbo].[Penaly] CHECK CONSTRAINT [BorrowIDfkforPenalty]
GO
ALTER TABLE [dbo].[Student]  WITH CHECK ADD  CONSTRAINT [DepartmentID] FOREIGN KEY([DepartmentID])
REFERENCES [dbo].[Department] ([DepartmentID])
GO
ALTER TABLE [dbo].[Student] CHECK CONSTRAINT [DepartmentID]
GO
ALTER TABLE [dbo].[Book]  WITH CHECK ADD  CONSTRAINT [chkBookCount] CHECK  (([BookCount]>=(1) AND len([ISBN])=(11)))
GO
ALTER TABLE [dbo].[Book] CHECK CONSTRAINT [chkBookCount]
GO
ALTER TABLE [dbo].[BorrowedBook]  WITH CHECK ADD  CONSTRAINT [chkforBorrowed] CHECK  ((([UserType]='2' OR [UserType]='1') AND [ReturnDate]>[BorrowDate]))
GO
ALTER TABLE [dbo].[BorrowedBook] CHECK CONSTRAINT [chkforBorrowed]
GO
ALTER TABLE [dbo].[NonBorrow]  WITH CHECK ADD  CONSTRAINT [chkUsertypeandkind] CHECK  ((([UserType]='2' OR [UserType]='1') AND ([Book_Kind]='2' OR [Book_Kind]='1')))
GO
ALTER TABLE [dbo].[NonBorrow] CHECK CONSTRAINT [chkUsertypeandkind]
GO
ALTER TABLE [dbo].[Penaly]  WITH CHECK ADD  CONSTRAINT [chkforPenalty] CHECK  (([UserType]='2' OR [UserType]='1'))
GO
ALTER TABLE [dbo].[Penaly] CHECK CONSTRAINT [chkforPenalty]
GO
