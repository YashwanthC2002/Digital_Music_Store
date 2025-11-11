select * from artist
select * from album
select * from track
select * from mediatype
select * from playlist
select * from playlisttrack
select * from invoice
select * from invoiceline
select * from employee
select * from customer
select * from genre

-- Using SQL solve the following problems using the chinook database.

-- 1) Find the artist who has contributed with the maximum no of albums. 
-- Display the artist name and the no of albums.
select a.name, count(aa.albumid) as no_of_album from artist a join album aa on aa.artistid = a.artistid
group by a.name
order by 2 desc
limit 1

with temp as
    (select alb.artistid
    , count(1) as no_of_albums
    , rank() over(order by count(1) desc) as rnk
    from Album alb
    group by alb.artistid)
select art.name as artist_name, t.no_of_albums
from temp t
join artist art on art.artistid = t.artistid
where rnk = 1;

)
-- 2) Display the name, email id, country of all listeners who love Jazz, Rock and Pop music.
select c.firstname || ' ' || c.lastname as fullname, c.email, c.country from customer c 
join invoice i on c.customerId = i.customerId
join invoiceline ii on ii.invoiceid = i.invoiceid
join track t on t.trackid = ii.trackid
join genre g on g.genreid = t.genreid
where g.name in ('Jazz','Rock','Pop')


-- 3) Find the employee who has supported the most no of customers. Display the employee name and designation
with cte as ( select concat(e.firstname,' ',e.lastname) as fullname, e.title, count(*),
 rank() over(order by count(*) desc) rnk
 from employee e
 join customer c on e.employeeid = c.supportrepid
 group by e.employeeid)
 select fullname, title from cte
 where rnk = 1
 
-- 4) Which city corresponds to the best customers?
with cte as(select c.city, sum(i.total), rank() over (order by sum(i.total) desc) rnk
from customer c 
join invoice i on c.customerid = i.customerid
group by 1)
select city from cte where rnk = 1


-- 5) The highest number of invoices belongs to which country?
with cte as (select billingcountry, rank() over(order by count(total) desc) rn from invoice
group by 1)
select * from cte where rn = 1

-- 6) Name the best customer (customer who spent the most money).
with cte as(select concat(c.firstname,' ', c.lastname) as fullname, sum(i.total),rank() over(order by sum(i.total) desc) rn
from customer c
join invoice i on c.customerid = i.customerid
group by 1)
select * from cte where rn = 1

-- 7) Suppose you want to host a rock concert in a city and want to know which location should host it.
select i.billingcity,count(*) from invoice i
join invoiceline il on il.invoiceid = i.invoiceid
join track t on t.trackid = il.trackid
join genre g on g.genreid = t.genreid
where g.name = 'Rock'
group by 1
order by 2 desc

-- 8) Identify all the albums who have less then 5 track under them.
--     Display the album name, artist name and the no of tracks in the respective album.
select a.title, aa.name, count(t.trackid) as no_of_tracks from album a
join artist aa on aa.artistid = a.artistid
join track t on t.albumid = a.albumid
group by 1,2
having count(*)<5

-- 9) Display the track, album, artist and the genre for all tracks which are not purchased.
-- CORELATED SUBQUERY (IT WILL RETURN TRUE OR FALSE ) EXISTS OR NOT EXISTS
select t.name, aa.title, a.name, g.name
from artist a
join album aa on aa.artistid = a.artistid
join track t on t.albumid = aa.albumid
join genre g on g.genreid = t.genreid
where not exists(
	select * 
	from invoiceline i1
	where i1.trackid = t.trackid
)
-- 10) Find artist who have performed in multiple genres. Diplay the aritst name and the genre.
with cte as (
	select distinct a.name as artist_name, g.name as genre from track t
	join  album aa on aa.albumid = t.albumid
	join artist a on a.artistid = aa.artistid
	join genre g on g.genreid = t.genreid
	order by 1,2), 
cte2 as(
	select artist_name
    from cte
    group by artist_name
    having count(*) > 1
)
select * from cte2
join cte on cte.artist_name = cte2.artist_name


-- 11) Which is the most popular and least popular genre?
with cte as(
	select g.genreid, g.name, count(i.invoicelineid) as total
	from genre g
	join track t on g.genreid = t.genreid
	join invoiceline i on t.trackid = i.trackid
	group by 1,2
	)
select name,total
from cte
where total = (select max(total) from cte)
union all
select name,total
from cte
where total = (select min(total) from cte)

-- 12) Identify if there are tracks more expensive than others. If there are then
--     display the track name along with the album title and artist name for these expensive tracks.
select t.name as track_name, aa.title as album_name, a.name as artist_name from Track t
join album aa on aa.albumid = t.albumid
join artist a on a.artistid = aa.artistid
where unitprice > (select min(unitprice) from Track)

    
-- 13) Identify the 5 most popular artist for the most popular genre.
--     Popularity is defined based on how many songs an artist has performed in for the particular genre.
--     Display the artist name along with the no of songs.
--     [Reason: Now that we know that our customers love rock music, we can decide which musicians to invite to play at the concert.
--     Lets invite the artists who have written the most rock music in our dataset.]
with genre_popularity as (
    select 
        g.GenreId,
        g.Name as genre_name,
        count(t.TrackId) as total_songs,
        rank() over (order by count(t.TrackId) desc) as genre_rank
    from Track t
    join Genre g on g.GenreId = t.GenreId
    group by g.GenreId, g.Name
),
most_popular_genre as (
    select GenreId, genre_name
    from genre_popularity
    where genre_rank = 1
)
select 
    ar.Name as artist_name,
    count(t.TrackId) as no_of_songs
from Track t
join Album al on t.AlbumId = al.AlbumId
join Artist ar on al.ArtistId = ar.ArtistId
join most_popular_genre mpg on mpg.GenreId = t.GenreId
group by ar.Name
order by no_of_songs desc
limit 5;

-- 14) Find the artist who has contributed with the maximum no of songs/tracks. 
-- Display the artist name and the no of songs.
with cte as (
    select a.name,count(1),rank() over(order by count(*) desc) as rnk
    from track t
    join album aa on aa.albumid = t.albumid
    join artist a on aa.artistid = a.artistid
    group by 1
    order by 2 desc)
select * from cte
where rnk = 1;


-- 15) Are there any albums owned by multiple artist?
select *
from album
group by albumid
having count(1)>1
 
-- 16) Is there any invoice which is issued to a non existing customer?
select * 
from invoice i
where not exists(select * from customer c
where c.customerid = i.customerid)

-- 17) Is there any invoice line for a non existing invoice?
select * 
from invoiceline i
where not exists(select * from)

-- 18) Are there albums without a title?
select * from album where title is null

-- 19) Are there invalid tracks in the playlist?
select * from playlisttrack p where not exists(select * from track t where p.trackid = t.trackid)
