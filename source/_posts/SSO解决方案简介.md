---
title: SSO解决方案简介
date: 2025-04-10 16:37:11
tags:
- 单点登录
- SSO
- OAuth
- CAS
- OIDC
- SAML2
categories:
- 安全技术
---
# 什么是SSO，为什么需要SSO

如果单从字面意思来理解，SSO表达了一种什么样的含义？我们知道，SSO的中文翻译为单点登录，顾名思义，即为单点，则表示在一个地方登录，登录的结果便是可以在多个地方被使用。在生活中常见的B/S场景下，我们有时需要通过用户名密码来声明我们对某个网站的某些资源具有访问权限，如果存在多个这样的网站，出于安全考虑我们可能就需要每一个网站均通过不同的用户名密码来声明对这些资源的访问权限，这就导致我们需要记录大量的密码以及反复完成登录操作，这个过程是繁琐且容易出错的。SSO的出现便能在一定程度上对这个缺陷进行弥补。

当然，如果仅仅是出于便利性的需要，SSO技术可能仍不是那么紧要。SSO技术使得对于某一类网站，如：同一公司旗下的一组网站，用户只需在某一个统一的入口完成一次登录操作便可同时访问这一组网站所有的受限资源，并能够完成权限控制、统一的会话管理、统一的资源分配等其他操作，这使得受限资源的保密性、完整性以及可用性有不同程度的提高。

SSO技术不仅仅是对用户认证产生了正向的影响，其解决的另一个问题是为不受信第三方获取资源提供了一整套的解决方案，即第三方获取资源的授权问题。

我们例举一个具体的SSO技术方案来进行说明，这里引用OAuth2.0 规范中关于为什么需要OAuth的说明。

传统的受限资源访问方案往往是通过使用资源所有者的访问凭据来获取资源的访问权限，这种通过明文凭据的访问方案往往用于声明用户对某个资源的所有权，而不能很好地向第三方进行资源分配。传统地方案在应用于第三方应用对受限资源的方式时往往会面临以下四个方面的问题：

- 第三方应用需要存储资源所有者的访问凭据，典型的方案就是用户名密码，这种方案显然是危险的，资源所有者不完全可以确认第三方应用地可信性；
- 受限资源通过密码访问，但密码体系本身存在各种各样的安全问题，如：泄露、强度问题等；
- 第三方应用通过密码获取到的访问权限太过广泛，资源所有者并没有很好的办法对这个范围进行限制，这往往需要配合其他的权限控制方案进行实现，如：RBAC，ABAC等；
- 资源所有者不能很好地对第三方应用对受限资源得访问进行控制，如：撤销权限，变更权限等操作，要做到这些往往需要通过修改密码以及变更角色权限的方式来实现。

正因为传统的密码体系对受限资源的访问控制在应用到第三方应用的过程中存在的这些缺陷使然，亟需一种灵活、便捷、有效、安全的第三方应用访问受限资源的解决方案。如OAuth，CAS，OIDC，SAML等协议框架正是为了解决这些问题而诞生。

整体来讲，这些框架的基本原理是一致的，区别在于它们如何看待认证与授权过程中涉及到的各种对象以及如何描述他们之间的关系再辅以不同的数据传输与处理方案，比如：OIDC便基本上就是是基于OAuth 2.0基础上实现的一个框架，SAML与OAuth 2.0的隐式模式在表现上最大的差别也就在数据结构上面，CAS与OAuth 2.0的隐式模式也很相似，至少展露给用户的部分是极其相似的，区别在于CAS能够处理用户认证与授权，OAuth 2.0只负责处理授权且在CAS中第三方应用携带ticket去请求资源时会根据用户进行权限校验，而OAuth 2.0的权限授予在申请Access Token时便已经完成了。

下面我们将以OAuth 2.0授权框架为主体对常见的SSO解决方案进行一个认识。
<!--more-->



# 常见SSO协议

## OAuth 2.0

Oauth 2.0授权框架允许第三方的应用程序通过与资源所有者进行交互或者以自身的名义来以HTTP的方式来获取受限资源的部分访问权限。该框架是在OAuth 1.0的基础上发展起来的，其是OAuth 1.0的替换以及发展，而在框架详细规范上OAuth 2.0与OAuth 1.0则大相径庭，两者不能互相兼容。OAuth 2.0是一个授权协议，与用户认证相关的部分并不在该框架的讨论范围类，但一般来说认证与授权是不分家的，认证是授权的基石，即便是OAuth 2.0框架也是在Clients获得了资源所有者身份认证之后才能进行进一步的授权，这正是OAuth 2.0所讨论的。

在OAuth2.0框架中组合要涉及到4个主体，即：资源所有者、资源服务提供者、客户端以及授权服务。其中资源所有者享有对资源服务提供者提供的资源的完全控制权力，资源服务提供者负责提供受保护的资源并响应通过Access Token发起的受保护资源请求，客户端是资源所有者的代理其并不表示任一具体的实现（应用程序）乃是一种抽象的概念，授权服务负责向经过认证的客户端下发Access Token。

### 授权方案

一个通用的OAuth 2.0协议处理流程是这样的：

![image-20240103112709252](image-20240103112709252.png)

关于上图做如下解释：

（A）客户端向资源所有者请求授权。主要通过两者方式，一种是客户端（第三方应用）直接向资源所有者请求凭据，另一种则是通过授权服务作为中介请求凭据。直接请求凭据的方式客户端会存储资源所有者的明文凭据，存在安全性风险，一般只在客户端类型为Confidential 以及许可类型为客户端时使用，实践中常见的均为通过授权服务作为中介的方式请求凭据；

（B）客户端接收授权许可，这个许可表示了资源所有者的授权。在规范中共规定了4种标准的许可类型以及其他可自行定义的许可方式；

（C）客户端使用获得的授权许可向授权服务获取Access Token；

（D）授权服务在对客户端进行认证并校验了授权许可的正确性后下发Access Token；

（E）客户端通过上一步获得的Access Token向资源服务提供者请求资源；

（F）资源服务提供者在向授权服务验证Access Token的正确性后向客户端下发资源；

上文中提到OAuth 2.0规范中提供了4中标准的许可类型，下面进行介绍：

#### 授权码类型

授权码类型的许可按照如下图的流程进行资源的授权访问：

![image-20240103144212336](image-20240103144212336.png)

（A）客户端通过资源所有者的代理（即用户浏览器）进行重定向将请求发送到授权服务端点。客户端请求包括client_id（标识客户端身份）、请求域（要申请哪些权限）、本地状态（随机数，防CSRF）以及一个将成功授权后的请求重定向的目标URI；

（B）授权服务对资源持有者的身份进行认证并确定资源持有者是否同意下发客户端请求的域；

（C）在授权成功的情况下，授权服务会将请求重定向到A过程中指定的重定向目标URI中，该URI将携带额外的授权码以及一些其他的状态参数；

（D）客户端请求携带client_id、client_secret以及授权码等向授权服务申请一个Access Token；

（E）授权服务在确认了客户端的合法性并校验了授权码后向向客户端下发Access Token 以及一个可选的Refresh Token。



#### 紧凑/隐式许可类型

紧凑/隐式许可类型的许可按照如下图的流程进行资源的授权访问：

![image-20240103154140345](image-20240103154140345.png)







（A）（B）同授权码类型（A）(B)

（C）授权通过的情况下，授权服务将Access Token 夹带在redirection URI fragment中进行返回

（D）用户代理向Web托管的客户端资源发起请求

（E）获取到一个带有嵌入时脚本的html页面，该脚本能够提取在C中得到的Access Token并与完整的重定向URI进行组合

（F）用户代理利用E中返回的脚本将Access Token与重定向URI进行组合

（G）用户代理将Access Token传递给客户端

#### 资源所有者密码凭据类型

资源所有者密码凭据类型的许可按照如下图的流程进行资源的授权访问：

![image-20240103155801548](image-20240103155801548.png)

（A）资源持有者直接向客户端提供其密码凭据

（B）客户端通过获取到的密码凭据向授权服务请求Access Token

（C）授权服务在验证了客户端合法性与凭据合法性后向客户端下发Access Token以及可选的Refresh Token

#### 客户端凭据许可类型

客户端凭据许可类型的许可按照如下图的流程进行资源的授权访问：



![image-20240103161547699](image-20240103161547699.png)

（A）客户端向授权服务发送自身的凭据

（B）授权服务验证客户端凭据的有效性并下发Access Token

## OIDC

OAuth 2.0只负责对资源的授权并不负责用户的认证，所以单纯地使用OAuth 2.0授权框架是不能完成用户认证的，而认证又是授权的基石，故在生产中我们往往不会见到单独使用的OAuth 2.0，其总是与其他的认证方案一起出现的。一种良好的既能兼顾认证又能兼顾授权的解决方案且基于OAuth 2.0的新的认证与授权解决方案便是OIDC。

OIDC与OAuth 2.0最大的区别就在于OIDC新增了ID Token作为用户的身份凭据。当然OIDC也在OAuth 2.0的基础上进行了一些丰富，如：服务发现等。

在OIDC中认证与授权过程中的角色有了新的名字：

- 授权服务器（OP-OpenID Provider）
- 终端用户（EU-End User）
- 受信客户端（RP-Relying Party）

OIDC中貌似忽略了OAuth 2.0的资源提供者这一角色，其实不然，只是被包含在了RP中。

OIDC的授权流程与OAuth 2.0基本一致，区别在于获取Access Token是，OIDC运行在授权码模式、隐式模式以及密码模式时会同时获取到ID Token以标识用户身份

下面是开源身份认证与授权应用KeyCloak的一个ID TOKEN

```shell
eyJhbGciOiJIUzI1NiIsInR5cCIgOiAiSldUIiwia2lkIiA6ICIzYjk0Y2YzMS03ZDYwLTQyYjUtYjA4YS1iZDVlYmYwYTA3ODQifQ.eyJleHAiOjE3MDUwNjM4MzMsImlhdCI6MTcwNTAyNzgzMywianRpIjoiYzYzZGYxNjItMTI2Mi00Nzk3LTkyOGMtNTkyMWFkOGFmMDk4IiwiaXNzIjoiaHR0cDovLzEyNy4wLjAuMTo4MDgwL3JlYWxtcy9tYXN0ZXIiLCJzdWIiOiJiYmUzMWE4NS1iNDk2LTQ3MWYtYTlkOS1hYjc5NjE4YjJhZjIiLCJ0eXAiOiJTZXJpYWxpemVkLUlEIiwic2Vzc2lvbl9zdGF0ZSI6IjNjYmNlOTAxLTZiODUtNDA4Ni04MWM4LThhZmUyZmQyM2FmNSIsInNpZCI6IjNjYmNlOTAxLTZiODUtNDA4Ni04MWM4LThhZmUyZmQyM2FmNSIsInN0YXRlX2NoZWNrZXIiOiIyYklaREE0OWV4d3RCRlFrNXg5SEZIWVBIaFpCZXNRcFNPOGo4UXNOMXBJIn0.GlF7wITRQqUonrtgOw26ewNFVGF8HdBUU1dd_MNmlQs
```

解码后为

![image-20240112105835688](image-20240112105835688.png)

在Payload部分定义了一些与用户身份相关的字段，如：sub，该字段标识了终端用户的ID。第三方应用在获取到该ID Token便可以使用该Token向`/userinfo`端点获取用户身份信息。

OIDC规范中定义了一些标准的用户信息，这些用户信息可以直接包含在`ID Token`中也可通过`userinfo`端点返回，参考：[Standard Claims](https://openid.net/specs/openid-connect-core-1_0.html#/StandardClaims)

![image-20240112105450001](image-20240112105450001.png)

## SAML2

SAML的全称为安全断言标记语言（Security Assertion Markup Language是一种开放标准，其允许身份提供商（IDP）将授权凭证传递给服务提供商（SP），使用可扩展标记语言（XML）进行IDP和SP之间的标准化通信。所谓IDP，顾名思义即提供身份认证的服务商，等同于OAuth 2.0中的授权服务（authorization server）以及OIDC中的（OP-OpenID Provider）；SP等同于OAuth 2.0中的资源服务（resource server）以及OIDC中的受信客户端（RP-Relying Party）。SP与IDP通过浏览器使用XML格式数据进行信息交互从而完成认证与授权操作，这个XML格式的数据就是断言。

SAML由一些构建块组成，当这些组件通过不同的方式组合在一起的时候就可以在不同场景下完成已经互相信任的自治系统之间对用户身份、属性、认证、授权信息的交换的需求，SAML规范的核心便是描述传输这些信息的断言和协议消息的结构与内容。

要完成这些目标，SAML体系定义了一些基本概念，如：Assertion，Protocols，Bindings，Profiles，Metadata，Authentication Context，Subject Confirmation。

![SAML concepts](sstc-saml-tech-overview-2.0-cd-02_html_73dc0b55.gif)

- **SAML断言**携带关于主体的声明，声明方声称该声明为真，依赖方解析该断言验证其完整性与有效性。断言的有效结构和内容由SAML断言的XML schema定义；
- **协议** 用于申明当前断言的类型，并绑定了不同的XML结构，该结构由XML schema限制，如：认证请求协议，单点登出协议，断言查询请求协议，Artifact 解析协议，身份标识管理协议，身份标识映射协议等；
- **绑定** 定义了SP与IDP是如何通过一些基础的协议（HTTP/SOAP等）进行交互的，如：HTTP 重定向绑定，HTTP POST绑定，HTTP Artifact绑定，SAML SOAP绑定，SAML URI绑定等；
- **SAML概要文件**以满足特定的业务用例，例如Web Browser SSO配置文件。概要文件通常在SAML断言、协议和绑定的内容上定义约束，其定义了三者如何相互协作以便可以互操作的方式解决业务用例，包括Web Browser SSO Profile，identity Provider Discovery Profile，Single Logout Profile等
- **元数据**是SAML个构建块之间一些共有的配置数据，如：密钥，身份属性、实体支持的绑定方式等
- **认证上下文** 某些情境下SP可能会需要用户在IDP进行认证时所用的认证方式以及强度等环境信息，这些信息便是SP的认证上下文。SP可以从断言消息的authentication statement节点中获取这些信息。当然，IDP可能也需要一些类似的环境信息，其也可以从SAML的Request中获取到它们。
- **主体确认** 帮助依赖方确认断言响应的主体与依赖方正在请求的主体是一致的。SAML2中定义了三种模式
  - urn:oasis:names:tc:SAML:2.0:cm:holder-of-key  # 通过密钥标识 依赖方需要声明与密钥的关系
  - urn:oasis:names:tc:SAML:2.0:cm:sender-vouches  # 由发送方指定断言由谁处理
  - urn:oasis:names:tc:SAML:2.0:cm:bearer  # 依赖方需要采取一些策略来判断是否具有对该断言的处理权限



SAML有多种应用场景，其中比较典型的两种分别时Web Browser SSO 以及Identity Federation。下面我们使用一个通过SAML来进行Web Browser SSO登录的例子来说明一些数据结构以及通过SAML来进行Web Browser SSO登录的流程，根据入口不同SAMl又有两种不同的消息流转方式，分别为SP-Initiated以及IDP-Initiated（qax的零信任，cy的404通行证），其中又以SP-Initiated在使用中最为常见。我们将以SP-Initiated的方式进行说明。



当用户访问某一个应用（SP）时，因为尚未取得认证与授权，此时SP会将请求重定向到IDP并携带SAML Request信息来请求IDP对用户身份进行认证。

SAML Request信息是一段被Base64编码的XML数据，解码后类似如下的格式：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<samlp:AuthnRequest
xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion"
ID="identifier_1"
Version="2.0"
IssueInstant="2004-12-05T09:21:59Z"
AssertionConsumerServiceIndex="1">
<saml:Issuer>https://sp.example.com/SAML2</saml:Issuer>
<samlp:NameIDPolicy
AllowCreate="true"
Format="urn:oasis:names:tc:SAML:2.0:nameid-format:transient"/>
</samlp:AuthnRequest>

```

当IDP接受到该请求后会响应给用户一个登录页面让用户输入身份凭据以验证用户身份，用户身份验证完成后IDP将响应给浏览器一个带自提交js脚本的页面将用户身份断言发送给SP，该断言经过解码后类似如下结构：

```xml
<samlp:Response
	xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
	xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="xxxx" Version="2.0" IssueInstant="xxxxx" Destination="https://xxx.idp.com/saml/SSO" InResponseTo="xxxxx">
	<saml:Issuer>https://xxx.idp.cn</saml:Issuer>
	<samlp:Status>
		<samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
	</samlp:Status>
	<saml:Assertion
		xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="xxxx" Version="2.0" IssueInstant="xxxxx">
		<saml:Issuer>https://xxx.idp.cn</saml:Issuer>
		<ds:Signature
			xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
			<ds:SignedInfo>
				<ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
				<ds:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
				<ds:Reference URI="#xxxxxx">
					<ds:Transforms>
						<ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
						<ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
					</ds:Transforms>
					<ds:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
					<ds:DigestValue>/xxxxxxxx</ds:DigestValue>
				</ds:Reference>
			</ds:SignedInfo>
			<ds:SignatureValue>xxxxx</ds:SignatureValue>
			<ds:KeyInfo>
				<ds:X509Data>
					<ds:X509Certificate>xxxxxx</ds:X509Certificate>
				</ds:X509Data>
			</ds:KeyInfo>
		</ds:Signature>
		<saml:Subject>
			<saml:NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified">test@test.example.com</saml:NameID>
			<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
				<saml:SubjectConfirmationData NotOnOrAfter="xxx" Recipient="https://xxx.xxx.com/saml/SSO" InResponseTo="xxxxx"/>
			</saml:SubjectConfirmation>
		</saml:Subject>
		<saml:Conditions NotBefore="xxx" NotOnOrAfter="xxxx">
			<saml:AudienceRestriction>
				<saml:Audience>https://xxx.xxx.com/xxxxxx/saml/SSO</saml:Audience>
			</saml:AudienceRestriction>
		</saml:Conditions>
		<saml:AuthnStatement AuthnInstant="xxxx" SessionIndex="xxxxx">
			<saml:AuthnContext>
				<saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:unspecified</saml:AuthnContextClassRef>
			</saml:AuthnContext>
		</saml:AuthnStatement>
		<saml:AttributeStatement>
			<saml:Attribute Name="email" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
				<saml:AttributeValue
					xmlns:xs="http://www.w3.org/2001/XMLSchema"
					xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">xxxx@xxxx.cn
				</saml:AttributeValue>
			</saml:Attribute>
			<saml:Attribute Name="name" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
				<saml:AttributeValue
					xmlns:xs="http://www.w3.org/2001/XMLSchema"
					xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string"/>
				</saml:Attribute>
				<saml:Attribute Name="username" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
					<saml:AttributeValue
						xmlns:xs="http://www.w3.org/2001/XMLSchema"
						xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">xxxx@xxx.xx
					</saml:AttributeValue>
				</saml:Attribute>
				<saml:Attribute Name="phone" NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic">
					<saml:AttributeValue
						xmlns:xs="http://www.w3.org/2001/XMLSchema"
						xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="xs:string">null
					</saml:AttributeValue>
				</saml:Attribute>
			</saml:AttributeStatement>
		</saml:Assertion>
	</samlp:Response>

```

可以看到，整体流程上和OAuth 2.0隐式模式并无太大差异，除了SAML2使用了断言这一数据结构来传输用户数据外，另一处差别便是在此模式下SAML的SP与IDP是不会直接进行通信的，而在OAuth 2.0以及OIDC中，Clients均会向授权服务器的token或者userinfo等端点访问以获取用户信息、Token等资料，导致该差别的原因只在于使用了form-bind的方式进行交互，若使用artifact-bind的方式便与授权码模式无异。

SAML不仅可以被单独用户SSO，其也可以嵌入到其他协议中作为一种数据结构来进行安全信息交换，如在OAuth2.0中通过Code 去获取Access Token时便可采用SAML的方式交换数据 [RFC7522](https://www.rfc-editor.org/rfc/rfc7522#/)。



# 常见攻击面

OAuth2.0规范中提及了以下的攻击手法：

- 凭据猜测攻击
- 钓鱼攻击
- 跨站请求伪造
- 点击劫持
- 代码注入
- 访问令牌滥用：隐式流+公共客户端
- 开放重定向

除了规范中提及的攻击手法，实践中因为规范的实现差异以及一些其他的技术问题OAuth在以下方面也存在薄弱面

- Access Token验证失败
- 开放客户端注册
- 客户端认证缺失
- 凭据泄露
- .well-known接口过度信息泄露



# 参考链接

- [RFC6749](https://datatracker.ietf.org/doc/html/rfc6749#/)
- [RFC7522](https://www.rfc-editor.org/rfc/rfc7522#/)
- [RFC7521](https://www.rfc-editor.org/rfc/rfc7521#/)
- [OpenID Connect Core 1.0 incorporating errata set 2](https://openid.net/specs/openid-connect-core-1_0.html#/)
- [https://docs.authing.co/v2/concepts/](https://docs.authing.co/v2/concepts/)
- https://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html#/