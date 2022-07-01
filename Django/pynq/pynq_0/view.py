from http.client import HTTPResponse
from urllib import request
from django.http import Http404, HttpRequest, HttpResponseNotFound
from django.http.response import HttpResponse, JsonResponse
from django.shortcuts import render

from . import tools
import json

def index(request: HttpRequest):
    return render(request, 'index.html')

def build(request:HttpRequest):
    if(request.method == 'POST'):
        content = json.loads(request.body.decode('utf-8'))
        ct = tools.build(content['content'], content['type'])
        return JsonResponse(ct)
    else:
        return HttpResponseNotFound()

def upload(request:HttpRequest):
    if(request.method == 'POST'):
        tools.upload()
        return HttpResponse('')
    else:
        return HttpResponseNotFound()

def run(request:HttpRequest):
    if(request.method == 'POST'):
        return JsonResponse({'data': tools.run()})
    else:
        return HttpResponseNotFound()

def perf(request: HttpRequest):
    if(request.method == 'POST'):
        return JsonResponse({'data': tools.read_trace()})
    else:
        return HttpResponseNotFound()

def init(request: HttpRequest):
    if(request.method == 'POST'):
        tools.init()
        return JsonResponse({'code': 0})
    else:
        return HttpResponseNotFound()