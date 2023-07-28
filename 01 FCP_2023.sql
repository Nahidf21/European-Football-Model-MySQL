----------- CREATE TABLES ------------

CREATE TABLE season (
seasonID INT PRIMARY KEY AUTO_INCREMENT,
seasonName VARCHAR(255)
);
CREATE TABLE team (
teamID INT PRIMARY KEY AUTO_INCREMENT,
teamName VARCHAR(100)
);
CREATE TABLE league (
leagueID INT PRIMARY KEY AUTO_INCREMENT,
leagueName VARCHAR(255)
);
CREATE TABLE division (
divisionID INT PRIMARY KEY AUTO_INCREMENT,
divisionName VARCHAR(255),
leagueID INT,
FOREIGN KEY (leagueID) REFERENCES league(leagueID)
);
CREATE TABLE referee (
refID INT PRIMARY KEY AUTO_INCREMENT,
Name VARCHAR(50)
);


CREATE TABLE fixture (
fixtureID INT PRIMARY KEY AUTO_INCREMENT,
seasonID INT,
refID INT,
Date DATE,
Time TIME,
htr CHAR(1),
ftr CHAR(1),
FOREIGN KEY (refID) REFERENCES referee(refID),
FOREIGN KEY (seasonID) REFERENCES season(seasonID)
);
CREATE TABLE team_fixture (
teamId INT,
fixtureId INT,
isHome bool,
shots SMALLINT,
shotsTarget SMALLINT,
corners SMALLINT,
fouls SMALLINT,
yellowCards SMALLINT,
redCards SMALLINT,
goalsHT SMALLINT,
goalsFT SMALLINT,
PRIMARY KEY (teamId, fixtureId),
FOREIGN KEY (teamId) REFERENCES team(teamID),
FOREIGN KEY (fixtureId) REFERENCES fixture(fixtureID)
);
CREATE TABLE team_season_division (
teamID INT,
seasonID INT,
divisionID INT,
PRIMARY KEY (teamID, seasonID),
FOREIGN KEY (seasonID) REFERENCES season(seasonID),
FOREIGN KEY (divisionID) REFERENCES division(divisionID),
FOREIGN KEY (teamID) REFERENCES team(teamID)
);

----------- INSERT DATA ------------

INSERT INTO league (leagueName)
SELECT DISTINCT league AS leagueName
FROM fcp_2023.results_csv;

select * from league;

INSERT INTO division (divisionName, leagueID)
SELECT DISTINCT `div` AS divisionName, l.leagueId
FROM fcp_2023.results_csv r
JOIN league l on r.league = l.leagueName;

select * from division;

INSERT INTO season (seasonName)
SELECT DISTINCT season AS seasonName
FROM fcp_2023.results_csv;

insert into referee (Name)
select r.referee as Name
from fcp_2023.results_csv r;

select * from referee;

insert into team (teamName)
select distinct r.homeTeam 
from fcp_2023.results_csv r
union
select distinct r.awayTeam
from fcp_2023.results_csv r;

select * from team;


INSERT INTO team_season_division (teamId, seasonId, divisionID)
SELECT DISTINCT teamId, seasonId, divisionID
FROM fcp_2023.results_csv r
JOIN team t on t.teamName = r.homeTeam
JOIN season s on s.seasonName = r.season
JOIN division d on d.divisionName = r.`div`
UNION
SELECT DISTINCT teamId, seasonId, divisionID
FROM fcp_2023.results_csv r
JOIN team t on t.teamName = r.awayTeam
JOIN season s on s.seasonName = r.season
JOIN division d on d.divisionName = r.`div`;

select * from team_season_division;

INSERT INTO fixture (seasonID,refID,Date,Time,htr,ftr)
SELECT
seasonId,
refId,
date,
time,
htr,
ftr
FROM fcp_2023.results_csv results
JOIN season s on results.season = s.seasonName
LEFT JOIN referee refs on results.referee = refs.Name;

select * from fixture;

insert into team_fixture (teamId,fixtureId,isHome,shots,shotsTarget,corners,fouls,yellowCards,redCards,goalsHT,goalsFT)
SELECT
t.teamId,
fixtureID,
1 isHome,
hs shots,
hst shotsTarget,
hc corners,
hf fouls,
hy yellowCards,
hr redCards,
hthg goalsHT,
fthg goalsFT
FROM fcp_2023.results_csv r
join team t on t.teamName = r.homeTeam
join fixture f on f.date = r.date and f.time = r.time and f.ftr =
r.ftr and f.htr = r.htr;

select * from team_fixture;

INSERT INTO team_fixture(teamId,fixtureId,isHome,shots,shotsTarget,corners,fouls,yellowCards,redCards,goalsHT,goalsFT)
 SELECT
 t.teamId,
 fixtureID,
 0 isHome,
 `as` shots,
 ast shotsTarget,
 ac corners,
 af fouls,
 ay yellowCards,
 ar redCards,
 htag goalsHT,
 ftag goalsFT
 FROM fcp_2023.results_csv r
 join team t on t.teamName = r.awayTeam
 join fixture f on f.date = r.date and f.time = r.time and f.ftr = r.ftr and f.htr = r.htr;

select * from team_fixture;

----------- CHECK DATA MATCHES ORIGINAL SOURCE ------------
SELECT
 l.leagueName league,
 s.seasonName season,
 d.divisionName `div`,
 m.date,
 m.time,
 homeTeamName.teamName homeTeam,
 awayTeamName.teamName awayTeam,
 homeTeam.goalsFT fthg,
 awayTeam.goalsFT ftag,
 m.ftr,
 homeTeam.goalsHT hthg,
 awayTeam.goalsHT htag,
 m.htr,
 r.name referee,
 homeTeam.shots hs,
 awayTeam.shots `as`,
 homeTeam.shotsTarget hst,
 awayTeam.shotsTarget ast,
 homeTeam.fouls hf,
 awayTeam.fouls af,
 homeTeam.corners hc,
 awayTeam.corners ac,
 homeTeam.yellowCards hy,
 awayTeam.yellowCards ay,
 homeTeam.redCards hr,
 awayTeam.redCards ar
FROM fixture m
 JOIN season s on m.seasonID = s.seasonId
 JOIN team_fixture homeTeam on m.fixtureID = homeTeam.fixtureID and
homeTeam.isHome = 1
 JOIN team homeTeamName on homeTeamName.teamId = homeTeam.teamId
 JOIN team_season_division tsd on tsd.seasonId = m.seasonId and
homeTeam.teamId = tsd.teamId
 JOIN division d on tsd.divisionId = d.divisionID
 JOIN league l on l.leagueID = d.leagueId
 JOIN team_fixture awayTeam on m.fixtureID = awayTeam.fixtureID and
awayTeam.isHome = 0
 JOIN team awayTeamName on awayTeamName.teamId = awayTeam.teamId
 LEFT JOIN referee r on m.refID = r.refID
