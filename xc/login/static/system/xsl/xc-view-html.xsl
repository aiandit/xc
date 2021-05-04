<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:x="http://ai-and-it.de/xmlns/2020/xc"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="text()"/>

  <xsl:template match="text()" mode="xc-title"/>

  <xsl:template match="dict" mode="xc-title">XC</xsl:template>


  <xsl:template match="text()" mode="xml-dump">
    <span>
      <xsl:value-of select="."/>
    </span>
  </xsl:template>

  <xsl:template match="*" mode="xml-dump">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:if test="namespace-uri() != namespace-uri(..)">
      <xsl:text> xmlns="</xsl:text>
      <xsl:value-of select="namespace-uri()"/>
      <xsl:text>"</xsl:text>
    </xsl:if>
    <xsl:for-each select="@*">
      <xsl:text> </xsl:text>
      <xsl:value-of select="name()"/>
      <xsl:text>="</xsl:text>
      <xsl:value-of select="."/>
      <xsl:text>"</xsl:text>
    </xsl:for-each>
    <xsl:text>&gt;</xsl:text>
    <xsl:apply-templates mode="xml-dump"/>
    <xsl:text>&lt;/</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&gt;</xsl:text>
  </xsl:template>


  <xsl:template match="*" mode="view">
    <code style="white-space: pre;">
      <xsl:apply-templates select="." mode="xml-dump"/>
    </code>
  </xsl:template>



  <xsl:template match="/">
    <div>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="x:xc[x:dict/x:xapp != 'main']"/>

  <xsl:template match="x:xc">
    <xsl:apply-templates select="//x:dict/x:data/x:errs"/>
    <xsl:apply-templates/>
  </xsl:template>

  <xsl:template match="x:errs">
    <div class="errors">
      <xsl:for-each select="x:item">
        <div class="error {x:type}">
          <xsl:value-of select="x:errmsg"/>
        </div>
      </xsl:for-each>
    </div>
  </xsl:template>

  <xsl:template match="x:dict[x:view = 'path']">
    <div>
      <h5><xsl:value-of select="x:xapp"/>::<xsl:value-of select="x:view"/></h5>

      <div>
        <xsl:if test="x:data/x:lsl/x:info/x:path">
          <div class="xc-sl-view"
               data-view-url="/main/ajax_view?path={x:data/x:lsl/x:info/x:path}"
               data-view-filter="auto"
               data-view-target="dict-path-view">
          </div>
          <h6>Autoview</h6>
          <div>
            <button onclick="xc.showContent">Content</button>
            <button onclick="xc.go2(this.dataset.url)"
                    data-url="/main/view?path={x:data/x:lsl/x:path}">View</button>
            <button onclick="xc.go2(this.dataset.url)"
                    data-url="/main/edit?path={x:data/x:lsl/x:path}">Edit</button>
          </div>
          <div
              id="dict-path-view-document"
              >
          </div>
        </xsl:if>
      </div>

      <h5>Code</h5>
      <code>
        <xsl:apply-templates select="/*" mode="view"/>
      </code>
    </div>
  </xsl:template>
  
  <xsl:template match="x:dict[x:view = 'view']">
    <div>
      <h5>Inline View</h5>
      <div
          id="dict-path-view-document"
          >
        <xsl:apply-templates select="." mode="inline-view"/>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="x:dict[x:view = 'edit']">
    <div>
      <h5>Inline Edit</h5>
      <div
          id="dict-path-view-document"
          >
        <xsl:apply-templates select="." mode="inline-edit"/>
      </div>
    </div>
  </xsl:template>
  
  <xsl:template match="text()" mode="inline-view"/>

  <xsl:template match="x:dict" mode="inline-view">
    <div>
      <h5>IV: Dict</h5>
      <xsl:apply-templates mode="inline-view"/>
    </div>
  </xsl:template>
  
  <xsl:template match="x:dir-actions" mode="inline-view">
    <div>
      <h5>IV: DA</h5>
      <ul class="flat-list">
        <xsl:for-each select="x:*">
          <li>
            <a href="/main/{x:action}?path={../../x:lsl/x:info/x:path}">
              <xsl:value-of select="x:name"/>
            </a>
          </li>
        </xsl:for-each>
      </ul>
      <xsl:apply-templates mode="inline-view"/>
    </div>
  </xsl:template>
  
  <xsl:template match="x:lsl/x:info" mode="link">
    <a href="/main/path?path={x:path}">
      <xsl:value-of select="x:type"/>
    </a>
    <xsl:text> </xsl:text>
    <span class="lsl-info-dirlink">
      <a href="/main/path?path={x:dir}">
        <xsl:value-of select="x:dir"/>
      </a>
      <b>/</b>
      <a href="/main/path?path={x:path}">
        <xsl:value-of select="x:name"/>
      </a>
    </span>
  </xsl:template>
  
  <xsl:template match="x:lsl/x:info" mode="stats">
    Date/Time: <span class="unixtm">
      <xsl:value-of select="x:statdict/x:st_mtime"/>
    </span>
    Size: <span class="value-with-unit" data-unit="B">
      <span>
        <xsl:value-of select="x:statdict/x:st_size"/>
      </span>
      <span>B</span>
    </span>
  </xsl:template>
  
  <xsl:template match="x:lsl" mode="inline-view">
    <div>
      <h5>IV: LSL</h5>
      Name:
      <xsl:apply-templates select="x:info" mode="link"/>
      Stats:
      <xsl:apply-templates select="x:info" mode="stats"/>
      <xsl:apply-templates mode="inline-view"/>
    </div>
  </xsl:template>
  
</xsl:stylesheet>
