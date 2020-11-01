#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<sys/inotify.h>
#include<limits.h>
#include<unistd.h>
#include<stdlib.h>
#include<time.h>
#include<errno.h>
#include<stdbool.h>
char** sensitive; //sensitive[20][50];
int snum;
const uint32_t flags[]={IN_OPEN,IN_ACCESS,IN_CREATE,IN_MODIFY,IN_ATTRIB,IN_DELETE,\
    IN_DELETE_SELF,IN_MOVE_SELF,IN_MOVED_FROM,IN_MOVED_TO,IN_IGNORED,\
    IN_UNMOUNT,IN_CLOSE_WRITE,IN_CLOSE_NOWRITE,};
const char* fstr[]={"IN_OPEN","IN_ACCESS","IN_CREATE","IN_MODIFY","IN_ATTRIB",\
"IN_DELETE","IN_DELETE_SELF","IN_MOVE_SELF","IN_MOVED_FROM","IN_MOVED_TO",\
"IN_IGNORED","IN_UNMOUNT","IN_CLOSE_WRITE","IN_CLOSE_NOWRITE"};
void expfile(void){
    fprintf(stderr,"Error: About sensitivefname file\nDetails: %s\n",strerror(errno));
    exit(EXIT_FAILURE);
}
void expInotify(void){
    fprintf(stderr,"Error: About inotify\nDetails: %s\n",strerror(errno));
    exit(EXIT_FAILURE);
}
void expReadEvent(void){
    fprintf(stderr,"Error when reading events\nDetails: %s\n",strerror(errno));
    exit(EXIT_FAILURE);
}
void printTime(){
    time_t t=time(NULL);
    struct tm *tp = localtime(&t);
    printf("UTC+8 Time:\n");
    printf("%d:%d:%d in %d/%d/%d \n",tp->tm_hour,tp->tm_min,tp->tm_sec,tp->tm_year+1900,tp->tm_mon+1,tp->tm_mday);
}

bool getSensitiveFname(FILE *fp){
    if(fp==NULL){
        expfile();
        
        return false;
    }
    snum = 0;
    sensitive = (char **)malloc(20*sizeof(char*));
    // sensitive = new char*[20];
    for(int i=0;i<20;i++){
        //sensitive[i]=new char[50];
        sensitive[i]=(char*)malloc(255*sizeof(char));
    }
    char buffer[256];
    while(fgets(buffer,255,fp)!=NULL){
        strcpy(sensitive[snum],buffer);
        sensitive[snum][strlen(sensitive[snum])-1]='\0';
        snum++;
    }
    if(snum>20){
        expfile();
        return false;
    }
    if(snum==0){
        printf("empty file\n");
        exit(EXIT_FAILURE);
        return false;
    }
    return true;
}
/*
struct inotify_event {
               int      wd;       // Watch descriptor 
               uint32_t mask;     // Mask describing event 
               uint32_t cookie;   // Unique cookie associating related
                                     events (for rename(2)) 
               uint32_t len;      // Size of name field 
               char     name[];   // Optional null-terminated name 
           };
*/
void printfInotifyEvent(const struct inotify_event * nevent){
    int mask = nevent->mask;
    int flen = sizeof(flags)/sizeof(uint32_t);
    for(int i=0;i<flen;i++){
        if(mask&flags[i]){
            printf("%s ",fstr[i]);
        }
    }
    if(nevent->wd!=-1){
    /* Print the name of the file */
        printf("of %s",sensitive[nevent->wd-1]);
        if (nevent->len>0){
            printf("/%s",nevent->name);
        }
        printf(" %s\n",(mask&IN_ISDIR)?"[dir]":"[file]");
        printf("~~~wd=%d and events_cookie = %d~~~\n",nevent->wd,nevent->cookie);
    }
    else if(mask&IN_Q_OVERFLOW){
            printf("===Too many events,so the event_queue overflow===\n");
    }
}
#define EVENT_BUF_LEN (10*(sizeof(struct inotify_event) + NAME_MAX + 1))
void readEvent(int inotify_fd){
    char * event_buf=malloc(EVENT_BUF_LEN);
    while (1) //next event
    {
        int bytesRead = read(inotify_fd,event_buf,EVENT_BUF_LEN);
        /* If the nonblocking read() found no events to read, then
                  it returns -1 with errno set to EAGAIN. In that case,
                  we exit the loop. */
        if(errno != EAGAIN && bytesRead==-1)
            expReadEvent();
        if(bytesRead < 0){ // sizeof(struct inotify_event)
            // printf("No events!\n")
            return;
        }
        //print one event
        printf("============================================\n");
        printTime();
        const struct inotify_event *event;
        for (char* pos = event_buf; pos < event_buf+bytesRead; pos+=sizeof(struct inotify_event) + event->len)
        {
            event = (const struct inotify_event*)pos;
            printfInotifyEvent(event);
            
        }
        
    }

}
int main(){
    FILE *fp = fopen("sensitivefname","r+");
    if(fp==NULL){
        expfile();
    }
    getSensitiveFname(fp);
    fclose(fp);
    fp=NULL;

    int inotifyFd = inotify_init();
    if(inotifyFd == -1){
        expInotify();
    }
    int result;
    //the file watched should exist before start.
    for(int i=0;i<snum;i++){
        // printf("index = %d\n",i);
        result = inotify_add_watch(inotifyFd,sensitive[i],IN_ALL_EVENTS|IN_EXCL_UNLINK);
        if(result==-1){
	        expInotify();
        }
        printf("Watching %s successfully,which watch_descriptor is %d\n",sensitive[i],result);
    }
    readEvent(inotifyFd);
    close(inotifyFd);

    return 0;


}
/*
For vim, Opening files and modifying files will involve temporary files
,so there are many incidents.
*/
//reference:https://man7.org/linux/man-pages/man7/inotify.7.html

/*
Inotify monitoring is inode-based: when monitoring a file (but not
       when monitoring the directory containing a file), an event can be
       generated for activity on any link to the file (in the same or a dif‐
       ferent directory).

       When monitoring a directory:

       *  the events marked above with an asterisk (*) can occur both for
          the directory itself and for objects inside the directory; and

       *  the events marked with a plus sign (+) occur only for objects
          inside the directory (not for the directory itself).

       Note: when monitoring a directory, events are not generated for the
       files inside the directory when the events are performed via a path‐
       name (i.e., a link) that lies outside the monitored directory.

       When events are generated for objects inside a watched directory, the
       name field in the returned inotify_event structure identifies the
       name of the file within the directory.
*/
