import json

with open('nsdinew.json') as f:
    data = json.load(f)


recentauthors = {} 

for key in data['result']['hits']['hit']:
    year = int(key['info']['year'])
    infoobject = key['info']
    if (year >= 2015 and year <= 2020):
        title = key['info']['title']
        for key2 in infoobject:
            if (key2 == "authors"):
                authors = key2,infoobject[key2]
                #print authors
                authorlist = authors[1]
                #print type(authorlist)
                for keys in authorlist['author']:
                    #print keys
                    #print type(keys)
                    try:
                        #print keys['text']
                        #print type(keys['text'])
                        name = str(keys['text'])
                        if (name not in recentauthors.keys()):
                            recentauthors[name] =  year
                        else:
                            if (year > recentauthors[name]):
                                recentauthors[name] =  year
                    except:
                        print "failure"
                #print type(authors)
                #for author in authors:
                #        print author
                #authors = key2.infoobject[key2]
                #print title

for author in sorted(recentauthors):
    print author + "," + str(recentauthors[author])
