Only keep groups without duplicated accounts hash sql

github
https://tinyurl.com/y97evcg7
https://github.com/rogerjdeangelis/utl-only-keep-groups-without-duplicated-accounts-hash-sql


related to
https://tinyurl.com/y8yqgshx
https://communities.sas.com/t5/SAS-Programming/filtering-data-based-on-a-condition-in-a-dataset/m-p/644024

    Two Solutions
        a. SQL
        b. HASH ( I am a novice hash programmer)
           based on work by
           Bartosz Jablonski
           yabwon@gmail.com  and mark
           and
           Keintz, Mark
           mkeintz@wharton.upenn.edu (simplification of h.add)

     You can do this without normalization by traversing an array within the HASH solution.
     However, normalization is a better data structure.

*_                   _
(_)_ __  _ __  _   _| |_
| | '_ \| '_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
;


data have ;
  input id $ account1 $ account2 $ ;
cards4;
AAA A1234 B1456
AAA A1234 B74156
AAA A2345 A2345
BBB B2546 C1254
BBB B4578 C12456
BBB B7995 C14576
BBB B1245 C1259
CCC D4568 F1254
CCC D4568 G1458
CCC D4568 D4568
;;;;
RUN;quit;

WORK.HAVE total obs=10        |  RULES
                              |
 ID     ACCOUNT1    ACCOUNT2  |
                              |
 AAA     A1234       B1456    |  Do not output this grpup
 AAA     A1234       B74156   |  because A1234 occurs twice
 AAA     A2345       A2345    |
                              |
 BBB     B2546       C1254    |  Output this group because
 BBB     B4578       C12456   |  there are no duplicatd accountss
 BBB     B7995       C14576   |
 BBB     B1245       C1259    |
                              |
 CCC     D4568       F1254    |  Do not output this grpup
 CCC     D4568       G1458    |  because D4568 occurs 4 times
 CCC     D4568       D4568    |


 *            _               _
  ___  _   _| |_ _ __  _   _| |_
 / _ \| | | | __| '_ \| | | | __|
| (_) | |_| | |_| |_) | |_| | |_
 \___/ \__,_|\__| .__/ \__,_|\__|
                |_|
;

WORK.WANT total obs=4

  ID     ACCOUNT1    ACCOUNT2

  BBB     B2546       C1254
  BBB     B4578       C12456
  BBB     B7995       C14576
  BBB     B1245       C1259


*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __  ___
/ __|/ _ \| | | | | __| |/ _ \| '_ \/ __|
\__ \ (_) | | |_| | |_| | (_) | | | \__ \
|___/\___/|_|\__,_|\__|_|\___/|_| |_|___/

;
*_                  _
| |__     ___  __ _| |
| '_ \   / __|/ _` | |
| |_) |  \__ \ (_| | |
|_.__(_) |___/\__, |_|
                 |_|
;

* normalize;
data havNrm / view=havNrm;
  set have;
  account="account1";
  val=account1;
  output;
  account="account2";
  val=account2;
  output;
  drop account1 account2;
run;quit;

proc sql;
  create
     table want_sql as
  select
     id
    ,account
    ,val
  from
     havNrm
  group
     by id
  having
     count (unique val) = count(val)
;quit;

data want_vue / view=want_vue;
  set want_sql curobs=rec;
  lagact=lag(val);
  if mod(rec,2)=0 then do;
     account1=lagact;
     account2=val;
     keep id account1 account2 ;
     output;
  end;
run;quit;

*_        _               _
| |__    | |__   __ _ ___| |__
| '_ \   | '_ \ / _` / __| '_ \
| |_) |  | | | | (_| \__ \ | | |
|_.__(_) |_| |_|\__,_|___/_| |_|

;

* normalize;
data havNrm / view=havNrm;
  set have;
  account="account1";
  val=account1;
  output;
  account="account2";
  val=account2;
  output;
  drop account1 account2;
run;quit;

data want;

    length _ $8;
    declare hash h ();
    h.defineKey ('_');
    h.defineDone();
    call missing(_);
      do until (last.id);
        set havNrm end=lr;
        by id;
        cnt+1;
        _n_=  h.add(key: val, data: "");  * if you remove `, data: vs` you will get
                                              an error which proves that even if you are
                                              declaring "only a key-hash" the data portion
                                              (equal to the key) is also defined :-) ;
      end;
      cnt_unique = h.num_items;
      _N_ = h.clear();
      do until (last.id);
        set havNrm end=lr curobs=rec;
        by id;
        account1=lag(val);
        if cnt=cnt_unique then do;
           if mod(rec,2)=0 then do;
              account2=val;
              keep id account1 account2;
              output;
           end;
        end;

      end;
      cnt=0;
      if lr then stop;
run;quit;

