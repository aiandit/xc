<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns="http://www.w3.org/1999/xhtml"
  version="1.0">

  <xsl:output method="xml" encoding="utf-8"/>

  <xsl:template match="*" mode="to-xhtml">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="to-xhtml"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="text()"/>

  <xsl:template match="/">
    <div class="xc">
      <div style="display: none">
	<form>
          <xsl:copy-of select="/*/csrf/*"/>
	</form>
      </div>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="xc">
    <xsl:variable name="loggedin-css">
      <xsl:if test="dict/user/is_authenticated = 'True'"> logged-in</xsl:if>
    </xsl:variable>
    <div class="xc-pad {dict/view}{$loggedin-css}">
      <div class="everon">
        <div id="pad-acts1">
          <table class="actions">
          <tr>
            <td>
              <a href="/main/home">Home</a>
            </td>
            <td>
              <a href="/main/path">Root</a>
            </td>
            <td>
              <a href="/main/find">Find</a>
            </td>
            <xsl:if test="dict/user/is_authenticated = 'True'">
              <td>
                <a href="/msgs/send?to=ac2">Msgs</a>
              </td>
            </xsl:if>
          </tr>
          </table>
        </div>
        <div id="pad-acts2">
          <table class="actions">
          <tr>
            <xsl:choose>
              <xsl:when test="dict/user/is_authenticated = 'True'">
                <xsl:if test="dict/user/is_superuser = 'True'">
                  <td>
                    <a class="xc-nocatch" href="/admin">Admin Page</a>
                  </td>
                </xsl:if>
                <td>
                  <a href="{/*/links/profile}"><xsl:value-of select="dict/user/username"/></a>
                </td>
                <td>
                  <a href="{/*/links/logout}">Logout</a>
                </td>
              </xsl:when>
              <xsl:otherwise>
                <td>
                  <a href="{/*/links/login}">Login</a>
                </td>
              </xsl:otherwise>
            </xsl:choose>
          </tr>
          </table>
        </div>
        <h3 id="pad-XC" class="oc-head">XC</h3>
        <div id="pad-docinfo" class="oc-body">
          <xsl:apply-templates select="dict/data/lsl/info" mode="lsl-info"/>
          <div id="xc-document-info"></div>
          <div id="xc-document-actions"></div>
          <xsl:apply-templates select="." mode="xc-pad"/>
        </div>
      </div>
    </div>
    <div class="main">
      <h2 id="xc-title" class="xc-title {dict/view}" title="XC view: {dict/xapp}/{dict/view}">
        &#160;
<!--        <xsl:apply-templates select="dict" mode="xc-title"/> -->
      </h2>
      <xsl:apply-templates select="dict"/>
      <div class="doc-messages">
        <div class="doc-float-messages">
        </div>
      </div>
    </div>
    <xsl:apply-templates select="dict" mode="doc-xcont"/>
    <xsl:apply-templates select="dict" mode="post-xcont"/>
  </xsl:template>

  <xsl:template match="text()" mode="doc-xcont"/>
  <xsl:template match="dict" mode="doc-xcont">
    <div class="document {xcontent/*/class[1]}">
<!--      <h4>Document View</h4> -->
      <div id="xc-document" class="xc-document {view}">
        <xsl:apply-templates select="/*" mode="showxcontent"/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="dict[view = 'home']" mode="doc-xcont">
    <div class="xc-sl-view"
	 data-view-url="/main/view?path=config.xml"
	 data-view-target="xc-home-view"
	 data-view-filter="config-view-html.xsl"
	 data-view-done="0"
	 >
      <div id="xc-home-view">
      </div>
    </div>
  </xsl:template>

  <xsl:template match="text()" mode="post-xcont"/>

  <xsl:template match="dict">
    <div>
      DICT handler not found
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <xsl:template match="dict" mode="xc-control-form">
    <xsl:if test="/*/forms/form[2]">
      <xsl:apply-templates select="." mode="xc-control-form-"/>
    </xsl:if>
  </xsl:template>

  <xsl:template match="dict" mode="xc-control-form-">
    <form id="xc-control" action="javascript:updateXView" method="get">
      <fieldset>
        <legend><xsl:value-of select="/*/forms/form[2]/@title"/></legend>
        <div>
          <table>
            <xsl:for-each select="/*/forms/form[2]/field">
              <tr>
                <th>
                  <xsl:apply-templates select="label" mode="to-xhtml"/>
                </th>
                <xsl:variable name="wnode" select="input|textarea|select"/>
                <td>
                  <xsl:apply-templates select="$wnode" mode="to-xhtml"/>
                </td>
                <td>
                  <xsl:apply-templates select="../error[@for = $wnode/@name]/msg/*" mode="to-xhtml"/>
                </td>
              </tr>
            </xsl:for-each>
            <tr>
              <td colspan="3">
                <input id="input-submit" type="submit" name="submit"/>
              </td>
            </tr>
          </table>
          <xsl:copy-of select="/*/csrf/*"/>
        </div>
      </fieldset>
    </form>
  </xsl:template>

  <xsl:template match="dict" mode="xc-form">
    <xsl:variable name="f1" select="/*/forms/form[1]"/>
    <h4>Form</h4>
    <xsl:if test="data/errs/item">
      <div class="aleft">
	<xsl:if test="cgi/next_">
	  <p>Form failure: <a href="{cgi/next_}">Return to form page</a></p>
	</xsl:if>
	<p>Errors:</p>
	<ul>
	  <xsl:for-each select="data/errs/item">
	    <li>
	      <xsl:value-of select="type"/>
	      <xsl:text>: </xsl:text>
	      <xsl:value-of select="errmsg"/>
	    </li>
	  </xsl:for-each>
	</ul>
      </div>
    </xsl:if>
    <form class="xc-form" id="{$f1/@id}" action="/{xapp}/{$f1/@action}" method="{$f1/@method}">
      <fieldset>
        <legend><xsl:value-of select="/*/forms/form[1]/@title"/></legend>
        <div>
          <table>
            <xsl:for-each select="/*/forms/form[1]/field">
              <tr>
                <th>
                  <xsl:apply-templates select="label" mode="to-xhtml"/>
                </th>
                <xsl:variable name="wnode" select="input|textarea|select"/>
                <td>
                  <xsl:apply-templates select="$wnode" mode="to-xhtml"/>
                </td>
                <td>
                  <xsl:apply-templates select="../error[@for = $wnode/@name]/msg/*" mode="to-xhtml"/>
                </td>
              </tr>
            </xsl:for-each>
            <tr>
              <td colspan="3">
                <input id="input-submit" type="submit" name="submit"/>
              </td>
            </tr>
          </table>
          <xsl:copy-of select="/*/csrf/*"/>
        </div>
        <xsl:if test="count(/*/dict/data/errs/item)">
          <div class="errors messages">
            <p>Errors occured:</p>
            <ul>
              <xsl:for-each select="/*/dict/data/errs/item">
                <li class="error error-type-{type}">
                  <div class="error">
                    <p class="error-msg">
                      <xsl:value-of select="errmsg"/>
                    </p>
                    <xsl:if test="details">
                      <code style="whitespace: pre;">
                        <xsl:value-of select="details"/>
                      </code>
                    </xsl:if>
                  </div>
                </li>
              </xsl:for-each>
            </ul>
          </div>
        </xsl:if>
      </fieldset>
    </form>
    <div class="xc-xcontent">
      <xsl:apply-templates select="/*" mode="showxcontent"/>
    </div>
  </xsl:template>

  <xsl:template match="text()" mode="showxcontent"/>

  <xsl:template match="/*" mode="showxcontent">
    <xsl:apply-templates select="(xcontent[count(*)>0]|xcontent-cdata)[1]" mode="showxcontent"/>
  </xsl:template>

  <xsl:template match="xcontent" mode="showxcontent">
<!--    <h4 class="oc-head">XML Content</h4>
    <code class="oc-body">
      <xsl:apply-templates select="*" mode="xml-dump"/>
    </code>-->
  </xsl:template>

  <xsl:template match="xcontent-cdata[string-length(.)>0]" mode="showxcontent">
    <h4 class="oc-head">Markup Content</h4>
    <code class="markup oc-body">
      <xsl:value-of select="."/>
    </code>
  </xsl:template>

  <xsl:template match="text()" mode="sendmsg-input"/>

  <xsl:template match="input|textarea|select" mode="sendmsg-input">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:copy-of select="@*"/>
      <xsl:attribute name="type">hidden</xsl:attribute>
      <xsl:apply-templates mode="to-xhtml"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="*[@name='data']" mode="sendmsg-input">
    <xsl:element name="{local-name()}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates mode="to-xhtml"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="dict" mode="sendmsg-form">
    <form id="{/*/forms/form[1]/@id}" action="/{xapp}/{/*/forms/form[1]/@action}" method="{/*/forms/form[1]/@method}">
      <fieldset>
        <div>
          <table>
            <xsl:for-each select="/*/forms/form[1]/field">
              <tr>
                <xsl:apply-templates select="." mode="sendmsg-input"/>
              </tr>
            </xsl:for-each>
            <tr>
              <td colspan="3">
                <input id="input-submit" type="submit" name="submit"/>
              </td>
            </tr>
          </table>
          <xsl:copy-of select="/*/csrf/*"/>
        </div>
        <xsl:if test="count(/*/dict/data/errs/item)">
          <div class="errors messages">
            <p>Errors occured:</p>
            <ul>
              <xsl:for-each select="/*/dict/data/errs/item">
                <li class="error error-type-{type}">
                  <div class="error">
                    <p class="error-msg">
                      <xsl:value-of select="errmsg"/>
                    </p>
                    <xsl:if test="details">
                      <code style="whitespace: pre;">
                        <xsl:value-of select="details"/>
                      </code>
                    </xsl:if>
                  </div>
                </li>
              </xsl:for-each>
            </ul>
          </div>
        </xsl:if>
      </fieldset>
    </form>
  </xsl:template>


  <xsl:template match="dict[xapp = 'main' and view = 'home']"
		mode="xc-title">XC Home</xsl:template>
  <xsl:template match="dict[xapp = 'main' and view = 'home']">
    <div class="xc-home">
    </div>
  </xsl:template>


  <xsl:template match="dict[xapp = 'login' and (view = 'index' or view = 'login')]" mode="xc-title">XC Login</xsl:template>
  <xsl:template match="dict[xapp = 'login' and (view = 'index' or view = 'login')]">
    <div>
      <p>
        Welcome to XC. Please login below
      </p>
      <xsl:apply-templates select="." mode="xc-form"/>
      <p>
        Want to become a member? Register in a minute with our <a
        href="{/*/links/register}">registration form</a>.
      </p>
      <p>
        Forgot password? Resend <a href="{/*/links/resendpassword}">here</a>
      </p>
    </div>
  </xsl:template>

  <xsl:template match="dict[xapp = 'register' and (view = 'index' or view = 'register')]" mode="xc-title">XC Register</xsl:template>
  <xsl:template match="dict[xapp = 'register' and (view = 'index' or view = 'register')]">
    <div>
      <p>
        Welcome to XC. To create an account, please register below
      </p>
      <xsl:apply-templates select="." mode="xc-form"/>
      <p>
        A member already? Login <a href="{/*/links/login}">here</a>.
      </p>
      <p>
        Registered already? A registration code has been sent to
        your email address. Activate your account <a
        href="{/*/links/activate}">here</a>
      </p>
    </div>
  </xsl:template>


  <xsl:template match="dict[xapp = 'register' and view = 'activate']" mode="xc-title">XC Activate</xsl:template>
  <xsl:template match="dict[xapp = 'register' and view = 'activate']">
    <div>
      <p>
        Welcome to XC. A registration code has been sent to your
        email address. Paste the code below to activate your account.
      </p>
      <xsl:apply-templates select="." mode="xc-form"/>
      <p>
        A member already? Login <a href="{/*/links/login}">here</a>
      </p>
      <p>
        Registration code not arrived? Resend <a href="{/*/links/resend-activation}">here</a>
      </p>
    </div>
  </xsl:template>

  <xsl:template match="dict[xapp = 'login' and view = 'resendpassword']" mode="xc-title">XC Resend Password</xsl:template>
  <xsl:template match="dict[xapp = 'login' and view = 'resendpassword']">
    <div>
      <p>
        Welcome to XC. In case you lost your password, we can send
        a one-time login code to your registered email address, using
        this form.
      </p>
      <xsl:apply-templates select="." mode="xc-form"/>
      <p>
        A member already? Login <a href="{/*/links/login}">here</a>
      </p>
      <p>
        Registration code arrived? Activate account <a href="{/*/links/activate}">here</a>
      </p>
    </div>
  </xsl:template>



  <xsl:template match="dict[xapp = 'register' and view = 'resend_activation']" mode="xc-title">XC Resend Activation</xsl:template>
  <xsl:template match="dict[xapp = 'register' and view = 'resend_activation']">
    <div>
      <p>
        Welcome to XC. A registration code has been sent to your
        email address. If the code does not arrive, you can request a
        resend here, by providing the email address used during
        registration.
      </p>
      <xsl:apply-templates select="." mode="xc-form"/>
      <p>
        A member already? Login <a href="{/*/links/login}">here</a>
      </p>
      <p>
        Registration code arrived? Activate account <a href="{/*/links/activate}">here</a>
      </p>
    </div>
  </xsl:template>


  <xsl:template match="dict[xapp = 'login' and view = 'profile']" mode="xc-title">XC Profile</xsl:template>
  <xsl:template match="dict[xapp = 'login' and view = 'profile']">
    <div>
      <p>
        Welcome to XC. This is your user profile.
      </p>
      <table>
        <xsl:apply-templates select="/*/dict/user" mode="table"/>
      </table>
      <p>
        Edit your profile  <a href="{/*/links/edit-profile}">here</a>.
      </p>
    </div>
  </xsl:template>

  <xsl:template match="user" mode="table">
    <xsl:for-each select="*">
      <tr>
        <td>
          <xsl:value-of select="local-name()"/>
        </td>
        <td>
          <xsl:value-of select="."/>
        </td>
      </tr>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="dict[xapp = 'login' and view = 'edit_profile']" mode="xc-title">XC Edit Profile</xsl:template>
  <xsl:template match="dict[xapp = 'login' and view = 'edit_profile']">
    <div>
      <p>
        Edit your profile info here.
      </p>
      <xsl:apply-templates select="." mode="xc-form"/>
      <p>
        View profile  <a href="{/*/links/profile}">here</a>.
      </p>
      <p>
        Reset password <a href="{/*/links/set-password}">here</a>.
      </p>
      <p>
        Delete your profile <a href="{/*/links/delete-profile}">here</a>.
      </p>
    </div>
  </xsl:template>

  <xsl:template match="dict[xapp = 'login' and view = 'deleteprofile']" mode="xc-title">XC Edit Profile</xsl:template>
  <xsl:template match="dict[xapp = 'login' and view = 'deleteprofile']">
    <div>
      <p>
        Delete your profile with this form.
      </p>
      <xsl:apply-templates select="." mode="xc-form"/>
      <p>
        View profile  <a href="{/*/links/profile}">here</a>.
      </p>
    </div>
  </xsl:template>

  <xsl:template match="dict[@mode = 'old']" mode="xc-form">
    <form name="{/*/forms/form[1]/@name}" action="/{xapp}/{/*/forms/form[1]/@action}" method="POST">
      <fieldset>
        <legend><xsl:apply-templates select="." mode="xc-title"/></legend>
        <table>
          <xsl:for-each select="/*/forms/form/field">
            <tr>
              <td>
                <xsl:apply-templates select="label" mode="to-xhtml"/>
              </td>
              <td>
                <xsl:apply-templates select="input|textarea" mode="to-xhtml"/>
              </td>
              <td>
                <xsl:apply-templates select="../error[@for = current()/input/@name]/msg/*" mode="to-xhtml"/>
              </td>
            </tr>
          </xsl:for-each>
          <xsl:if test="count(/*/dict/data/errs/item)">
            <tr>
              <td colspan="2">
                <div class="errors messages">
                  <p>Errors occured:</p>
                  <ul>
                    <xsl:for-each select="/*/dict/data/errs/item">
                      <li class="error error-type-{type}">
                        <xsl:value-of select="errmsg"/>
                      </li>
                    </xsl:for-each>
                    </ul>
                </div>
              </td>
            </tr>
          </xsl:if>
          <tr>
            <td colspan="2">
              <input id="input-submit" type="submit" name="submit"/>
            </td>
          </tr>
        </table>
        <xsl:copy-of select="/*/csrf/*"/>
      </fieldset>
    </form>
  </xsl:template>

  <xsl:template match="dict[xapp = 'login' and view = 'set_password']" mode="xc-title">XC Reset Password</xsl:template>
  <xsl:template match="dict[xapp = 'login' and view = 'set_password']">
    <div>
      <p>
        Reset your password with this form.
      </p>
      <xsl:apply-templates select="." mode="xc-form"/>
      <p>
        <a href="{/*/links/profile}">View</a> or <a href="{/*/links/edit-profile}">edit</a> profile.
      </p>
    </div>
  </xsl:template>

  <xsl:template match="dict[xapp = 'login' and view = 'reset_password']" mode="xc-title">XC Reset Password</xsl:template>
  <xsl:template match="dict[xapp = 'login' and view = 'reset_password']">
    <div>
      <p>
        Reset your password with this form.
      </p>
      <xsl:apply-templates select="." mode="xc-form"/>
      <p>
        After password reset, you can <a href="{/*/links/login}">login</a> again.
      </p>
    </div>
  </xsl:template>

  <xsl:template match="dict[xapp = 'login' and view = 'logout']" mode="xc-title">XC Logout</xsl:template>
  <xsl:template match="dict[xapp = 'login' and view = 'logout']">
    <div>
      <p>
        Log out form XC using this form.
      </p>
      <xsl:apply-templates select="." mode="xc-form"/>
      <p>
        Return to your profile  <a href="{/*/links/profile}">here</a>.
      </p>
    </div>
  </xsl:template>

  <xsl:template match="dict[xapp = 'main' and view = 'path']" mode="xc-title">XC Path - <xsl:value-of 
    select="data/lsl/info[1]/path"/></xsl:template>
  <xsl:template match="dict[xapp = 'main' and view = 'path']">
    <div>
      <xsl:apply-templates select="data/lsl"/>
    </div>
  </xsl:template>


  <xsl:template match="lsl">
    <div>
      <div class="file-info">
        <xsl:apply-templates select="finfo"/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="lsl/info" mode="lsl-info">
    <div class="info-actions lsl-info">
      <xsl:variable name="i1" select="/*/dict/data/lsl/info[1]"/>
      <xsl:apply-templates select="." mode="lsl-head"/>
      <table class="actions">
        <tr>
          <td>
            <a class="action {class}"
               href="/{/*/dict/xapp}/path?path={$i1/dir}">Parent</a>
          </td>
          <xsl:for-each select="/*/dict/data/dir-actions/item">
	    <xsl:if test="not(if) or (if = 'exec' and $i1/exec > 0)">
              <td>
		<xsl:variable name="psep">
                  <xsl:choose>
                    <xsl:when test="urlstyle > 0">/</xsl:when>
                    <xsl:otherwise>?path=</xsl:otherwise>
                  </xsl:choose>
		</xsl:variable>
		<a class="action {class}"
                   href="/{/*/dict/xapp}/{action}{$psep}{$i1/path}"><xsl:value-of select="name"/></a>
              </td>
	    </xsl:if>
          </xsl:for-each>
        </tr>
      </table>
    </div>
  </xsl:template>

  <xsl:template match="lsl/info" mode="lsl-head">
    <div>
      <h4>Item type <xsl:value-of select="type"/>: <xsl:value-of select="name"/></h4>
      <div>
        <h5>Info</h5>
        <table class="collection">
          <xsl:apply-templates select="."/>
        </table>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="lsl/info[type = '-']" mode="lsl-head">
    <div>
      <h4 class="oc-head">Document <xsl:value-of select="name"/></h4>
      <div class="oc-body oc-open">
        <h5>Info</h5>
        <table class="collection">
          <xsl:apply-templates select="."/>
        </table>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="lsl/info[type = 'd']" mode="lsl-head">
    <div>
      <h4>Collection <xsl:value-of select="name"/></h4>
      <div>
        <h5>Info</h5>
        <table class="collection">
          <xsl:apply-templates select="."/>
        </table>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="finfo">
    <table class="collection">
      <tr>
        <td colspan="4"><xsl:value-of select="count(item)"/> Items</td>
      </tr>
      <xsl:if test="/*/dict/data/lsl/info[1]/path != '/'">
        <tr>
          <td>d</td>
          <td>
            <a href="/{/*/dict/xapp}/path?path={/*/dict/data/lsl/info[1]/dir}">..</a>
          </td>
          <td></td>
          <td></td>
        </tr>
      </xsl:if>
      <xsl:apply-templates select="item">
        <xsl:sort select="name" order="ascending" data-type="text"/>
      </xsl:apply-templates>
    </table>
  </xsl:template>

  <xsl:template match="finfo/item|lsl/info">
    <tr>
      <td><xsl:value-of select="type"/><xsl:value-of select="perms"/></td>
      <td><a href="{/*/links/path}?path={path}"><xsl:value-of select="name[. != '']|path"/></a></td>
      <td class="unit-value">
       <span class="unit" data-unit="B" data-targetunit="KB"><xsl:value-of select="statdict/st_size"/>&#xa0;B</span></td>
      <td><span class="unixtm"><xsl:value-of select="statdict/st_mtime"/></span></td>
    </tr>
  </xsl:template>

  <xsl:template match="text()" mode="xc-pad"/>
  <xsl:template match="dict[view = 'edit' or view = 'view' or view = 'path']" mode="xc-pad">
    <div class="docform" id="xc-form">
      <h4 class="oc-head">Forms</h4>
      <div class="oc-body">
        <xsl:apply-templates select="." mode="xc-form"/>
        <xsl:apply-templates select="." mode="xc-control-form"/>
      </div>
    </div>
  </xsl:template>

  <xsl:template match="dict" mode="findcmd">
    <div class="findcmd" data-onform-update="/main/findcmd">
    </div>
  </xsl:template>

  <xsl:template match="dict[view = 'dirmanform']" mode="xc-title">
    <xsl:text>Form </xsl:text>
    <xsl:value-of select="/*/forms/form[1]/@title"/>
  </xsl:template>

  <xsl:template match="dict[view = 'dirmanform']">
    <div>
      <xsl:apply-templates select="." mode="xc-form"/>
      <xsl:if test="data/findlist">
        <div class="find">
          <xsl:choose>
            <xsl:when test="count(data/findlist/item) > 0">
              <xsl:choose>
                <xsl:when test="count(data/findlist/item) = 1">
                  <h4>Pattern found</h4>
                </xsl:when>
                <xsl:otherwise>
                  <h4><xsl:value-of select="count(data/findlist/item)"/> items found</h4>
                </xsl:otherwise>
              </xsl:choose>
              <table class="findlist">
                <xsl:for-each select="data/findlist/item">
                  <tr>
                    <td class="path">
                      <!--                  <span data-insert='1' data-fetch='/main/view?path={path}'> -->
                      <a href="/main/path?path={path}">
                        <xsl:value-of select="path"/>
                      </a>
                    </td>
                    <td class="file">
                      <!--                  <span data-insert='1' data-fetch='/main/view?path={path}/{name}'> -->
                      <a href="/main/view?path={path}/{name}">
                        <xsl:value-of select="name"/>
                      </a>
                    </td>
                  </tr>
                </xsl:for-each>
              </table>
            </xsl:when>
            <xsl:otherwise>
            </xsl:otherwise>
          </xsl:choose>
        </div>
      </xsl:if>
    </div>
  </xsl:template>


  <xsl:template match="dict[xapp = 'main' and view = 'view']" mode="xc-title">
    <xsl:text>View </xsl:text>
    <xsl:value-of select="/*/dict/cgi/path"/>
  </xsl:template>
  <xsl:template match="dict[xapp = 'main' and view = 'view']">
  </xsl:template>

  <xsl:template match="dict[xapp = 'main' and view = 'edit']" mode="xc-title">
    <xsl:text>Edit </xsl:text>
    <xsl:value-of select="/*/dict/cgi/path"/>
  </xsl:template>
  <xsl:template match="dict[xapp = 'main' and view = 'edit']">
    <div>
    </div>
  </xsl:template>

  <!-- no output from dirmanform -->
  <xsl:template match="dict[view = 'dirmanform']">
  </xsl:template>
  <xsl:template match="dict[view = 'dirmanform']" mode="xc-title">
  </xsl:template>


  <xsl:template match="dict[view = 'sendmsg']" mode="xc-title">
    <xsl:value-of select="/*/forms/form[1]/@title"/>
  </xsl:template>
  <xsl:template match="dict[view = 'sendmsg']"/>
  <xsl:template match="dict[view = 'sendmsg']" mode="post-xcont">
    <div class="postcont cboth">
      <xsl:apply-templates select="." mode="sendmsg-form"/>
    </div>
  </xsl:template>


  <xsl:template match="text()" mode="xml-dump">
    <span>
      <xsl:value-of select="."/>
    </span>
  </xsl:template>

  <xsl:template match="*" mode="xml-dump">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&gt;</xsl:text>
    <xsl:apply-templates mode="xml-dump"/>
    <xsl:text>&lt;/</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:text>&gt;</xsl:text>
  </xsl:template>


  <xsl:template match="xcontent" mode="view">
    <code style="white-space: pre;">
      <xsl:apply-templates select="*" mode="xml-dump"/>
    </code>
  </xsl:template>


</xsl:stylesheet>
