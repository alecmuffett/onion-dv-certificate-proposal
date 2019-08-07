## Press Coverage

* https://portswigger.net/daily-swig/how-tor-can-enable-verification-with-dv-certs

# SOOC: Same-Origin Onion Certificate checks for DV TLS

**A simple proposal to provide DV TLS certificates to Onion Sites**

## Outline

[Onion sites](https://tools.ietf.org/html/rfc7686) provide self-authenticating network addresses which offer high assurance that a user of "onion networking" is connected to the service - strictly: to the possessor of a cryptographic private key - which they intended.

This degree of assurance in the TCP/IP network stack is provided by certificate authorities who provide various checks prior of issuance of a certificate to a website owner. Depending upon the nature of the end certificate, some or all of these checks are redundant in the Onion networking space.

Onion-networking-enabled browsers are capable of delivering most, possibly all, of their streams-based services and user experiences over onion networking; this is evidenced by work at [Facebook](https://www.facebookcorewwwi.onion/) and the [New York Times](https://www.nytimes3xbfgragh.onion/) and [Cloudflare](https://blog.cloudflare.com/cloudflare-onion-service/), amongst others. These sites are equipped with EV certificates issued under the terms of [Ballot 144 of the CA/Browser Forum](https://cabforum.org/2015/02/18/ballot-144-validation-rules-dot-onion-names/) which opened up official provision for onion networking.

EV certificates are not available to individual users, and DV certificates are not available to onion addresses, for many reasons not least the justifiable liability concerns of Certificate Authorities; however the increasing popularity of onion networking, combined with the increasing number of applications which mandate use of HTTPS, leads towards a bifurcation of trust: that onion addresses offer high assurance, but there is no means for that to be leveraged in the HTTPS stack unless one is an organisation and capable of purchasing an EV certificate. This situation inhibits innovation in the network stack.

Also: there are considerations of HTTP/2, that in the TCP/IP network space, a single TCP connection which has been authenticated with a certificate offering SubjectAltNames of both `foo.com` and `bar.net`, will be treated as a pre-existing connection to `bar.net` for connection reuse even if the connection was originally made with the intention of fetching a resource from `foo.com`. It is probable that this level of trust may only be viable by provision of a licensed Certificate Authority as an arbiter.

However, this does not prohibit us from offering what we believe is a viable and simple solution for in-browser trust of DV certificates for onion addresses:

## Proposal

Consider a website with the onion address `examplewebsitexx.onion` offering services at URIs such as:

* `https://examplewebsitexx.onion`
* `https://www.examplewebsitexx.onion/foo.html`
* `https://m.staging.examplewebsitexx.onion/foo/bar.mp3`

A browser will consider a DV certificate to be valid for connections to this site, if one of the two following conditions is true:

### Condition 1: (already works)

* The connection certificate is a valid DV certificate (eg: such as those created by [Filippo Valsorda's `mkcert`](https://github.com/FiloSottile/mkcert))
* **and** the certificate satisfies the standard trust rules for the webpage in question
* **and** the certificate is signed by a Certificate Authority Key which matches a root certificate that has been manually added to the local trust store

...or...

### Condition 2: (to be added)

* The connection certificate is a valid DV certificate (eg: `mkcert`, again)
* **and** the certificate satisfies the standard trust rules for the webpage in question
* **but** the certificate is signed by a Certificate Authority Key that **cannot** be resolved in the local trust store
* **however** the rightmost label of **all Subject Alt Names in the certificate, without exception**, is `onion`
* **and** the rightmost two labels of **all Subject Alt Names in the certificate, without exception**, match those of the given onion site (ie: `examplewebsitexx.onion`)
* **and** no Common Name is supplied on the certificate
* **and** the certificate is a "leaf" / not used for validating other certs.

## Which browsers would this target?

The goal would be to put this in Firefox as a default-false option, and have TorBrowser and other Tor-aware clients set it to default-true as a matter of choice or design.

## Rationale

**Condition 1** has been extensively tested by the author, and is simple, obvious, and practically redundant: *it already works*. Extant web browsers do not take any special steps to avoid connections to `.onion` websites, and when connected to the Tor network they are abstracted from the network via a standard `SOCKS5` proxy which also performs name resolution, thereby obviating any DNS concerns.

**Condition 2** is novel, but conceptually simple: to validate a DV certificate fully for connecting to a given site - including, eg: failing validation if not-before / not-after date boundaries are exceeded - *except* to selectively ignore failure to validate the certificate chain / an inability to resolve the Certificate Authority Key Identifier, in the circumstances that the certificate **could exclusively and only be used to communicate with a "layer 7" onion address/sitename that corresponds to the exact same "layer 3" onion address**. 

I believe this proposal addresses the trust requirements of binding onion addresses to TLS certificates, preventing the issues of HTTP/2 connection reuse on the basis of Onion DV-certificates, and provides a self-serve route forwards for individuals to build-out onion services, via use of tools like `mkcert`.

This proposal also (currently) leaves open a non-exclusionary role[1] for existing EV Onion Certificates: for those purposes where more than one Onion address, or a mixture of Onion Addresses and DNS Names, **must** be present in a single certificate; at first consideration this would broadly be in line with the original vision of EV certificates as being "extra validated"

## Proposed Implementation

* Trap the failure condition where the certificate chain for a connection to `examplewebsitexx.onion` has been found not to validiate, on the specific grounds that the Certificate Authority Key Identifier cannot be found in the trust root.
  * Check that the certificate is DV
  * Check that the certificate is exclusively citing Subject Alt Names which end in two labels `examplewebsitexx.onion`
    * Don't just do a simple `strcmp()`, check the label boundaries because subdomains, etc; do it properly 
  * Check that there is no CN in the certificate
  * Check that you are processing a "leaf" certificate, not halfway up a chain of trust.
* If all conditions are met, ignore this specific failure condition and continue validation processing.

## Potential FAQs

* Q: What if a "real" CA issues a DV certificate containing both Onion and DNS addresses?
  * A: They're not allowed to, but in any case if someone really wanted one they could buy a "combo" EV certificate which can contain both already
* Q: Why repeat the "rightmost label" stuff?
  * A: Mostly emphasis / to suggest a "sniff test" for implementers; plus I was vaguely wondering about the converse, viz: whether it was necessary to somehow "ban" `mkcert` users from generating their own "combo" certs, before I realised that it would be foolish, fruitless and unnecessary to do so.
* Q: Why the CN thing?
  * A: The goal of requiring no Common Name is simply to be doubly-certain regarding potential for trust leaks; this may be redundant / pointless / is a matter for consideration.
* Q: why not self-signed certs?
  * A: Truly "self-signed certificates", suck. Aside from the aspect of "an infinite hell of security popups", there is also the matter that a solution would require "OMG we need to define a standard for a self-signed Onion Cert" and endless bickering; on the other hand, the above proposal is easy to explain and reason about.
* Q: isn't this the same as self-signed certs?
  * A: This is close, but not really the same as self-signed certs.  This proposal merely means that you can skip DV chain validation **if** it is not already possible **and** where there is no practicable benefit in doing so (because of the self-authenticating nature of onion addresses, and no risk of HTTP/2 circuit-reuse leaks)
* Q: you're relying on tor to provide a secure channel here, which ends at the egress tor node with its onion address private keys, so your path from that last hop to your httpd should be over localhost
  * A: yes, but you're presuming the implementer's intention, here. This is no more of an risk than a terminate-and-forward TCP/IP load-balancer would be (is) for an EV certificate.
* Q: Doesn't this mean that the cert will be issued to a network connection, rather than a person or company?
  * Basically the same as LetsEncrypt, then.
* Q: why all this fuss? Why not just make self-authenticating Tor connections accept "any old certificate"?
  * Various reasons, not least of which is remaining orthogonal with upstream application expectations; you wouldn't want to connect to an random onion website and have it (via its certificate) offering to provide a HTTP/2 connection back to facebook.com, would you? Unless it was the genuine facebook onion address via Alt-Svc headers, of course...
* Q: Why do certificate authorities not issue DV certificates for onions?
  * A: many reasons, mostly due to liability: stuff like *"ZOMG v2 onion addresses are 80 bits of truncated SHA1 hash and if an attacker had a few squillions of dollars to spare then they could collide a key... and we (certificate authorities) might get sued for issuing a cert to a collided key."* - which is fair enough. One joy of the self-service approach to Onion DV keys is an "on your own head, be it" approach to liability: it is neither more, nor less, risk than mining and using the address in the first place. See also this essay: https://medium.com/@alecmuffett/onions-certs-browsers-a-three-way-mexican-standoff-7dc987b8ebc8 
* Q: Can you simply short-cut Condition 1 if you see Condition 2?
  * A: Nope; because someone might be using Condition 1 in order to test an eventual EV-cert deployment architecture, including mixed Onion-and-DNS-Addresses amongst the SANs, which Condition 2 would forbid.
  
## Discussion: On "binding" Onion Addresses with SSL Certificates
  
The **EV** Onion Certificate mechanism [takes additional steps to embed a hash of the Onion public key](https://cabforum.org/pipermail/public/2017-April/010706.html) into the certificate; this was a last minute thought in the EV Onion Certificate specification, meant as some guarantee against "impersonating an onion site".   

I did not understand this choice from the outset, and in practice it has greatly complicated the issuance of EV onion certs with a demand for new and specialised tooling and process, to no apparent practical benefit. 

It was failure to embed a proper hash [(SEE IMAGE)](revoked-onions.png) which led to the [revocation of one NYT certificate](https://crt.sh/?id=240277340) and its [rapid replacement by another](https://crt.sh/?id=241547157) - so this requirement for an extra hash adds bureaucratic load, and possibility for error, and therefore adds cost; however I *did* install that certificate in the NYT for 24 hours, and it *did* work, so apparently no browser is checking this information.

Further: how does one "impersonate an onion site"? On reflection there might be some edge cases where that's a risk, but this is my take on it:

By definition an onion site someone who possesses a public key (and the corresponding private one) which they can register with the Tor network; the public key of the Onion address *is* Tor's defacto network address, and anyone with the corresponding private key can represent themselves as that Onion address *upon* the Tor network, and they *will* receive traffic for that network address.  

Unlike in the cleartext internet, **Tor's layer-3 behaviour is the source of truth** regarding network endpoint identity, rather than the contents of a HTTPS certificate which is supported by the infrastructures of IP-hosting, DNS-hosting, Certificate Authorities, and ISP behaviour. There is an absolute binding between (say) `facebookcorewwwi.onion` and Facebook, without reference to third parties.

### Mapping a Certificate to an Onion Address

If we are given a HTTPS certificate for an onion address, how do we know which Onion Public Key it is referring to? 

Simple: we look at the ("DNSName") onion addresses that are stored in the SubjectAltNames field: 

  * With v3 onion addresses, the onion address string is *literally* the entire public key; therefore the public key will be embedded, probably several times over, in the SubjectAltNames of the certificate; string comparison of the rightmost two labels will guarantee the binding, and the additional "cabf-TorServiceDescriptorHash" is unnecessary.
  * With v2 addresses, the onion address string is a 80-bit truncated SHA-1 hash of the public key; again string comparison of the rightmost two labels can provide the binding, but the question is whether a truncated hash is "sufficient" binding. The answer is yes, because the Tor network **itself** will accept as legitimate any public key which can match this hash, and will send traffic to it. (See "source of truth", above)

In the circumstances that an onion-address private/public keypair is leaked (irrespective of v2 or v3) then it is a "game-over" situation; there is absolutely no "putting the genie back in the bottle" as there might be on the cleartext internet where a (stale?) DNS domain is hijacked, its addresses redirected, and a LetsEncrypt DV certificate is issued for the hijacker's machines. 

### Mapping (in reverse) an Onion Address to a Certificate

If we are given an Onion Public Key / Address, how do we know what is the HTTPS Certificate for that connection?

Simple: we connect to the onion address, and we retrieve the certificate.  The layer-3 connection is defacto authenticated to a level which is similar to HTTPS, so any HTTPS certificate which we receive over such a connection can be assumed to be genuine. It is "true" because we received it over that link.

This leaves open three edge cases:

* What if - when connecting to a third party like `foo.com` - we receive a **DV certificate** which cites both `foo.com` and `bar.onion`, in the hope of stealing Onion traffic by means of redirecting it to `foo.com` because of `Alt-Svc` headers?
  * This cannot happen, because Certificate Authorities are forbidden from issuing DV certificates which contain onion addresses.
* What if - when connecting to a third party like `foo.com` - we receive a **EV certificate**  which cites both `foo.com` and `bar.onion`?
  * This is fine, and may be desirable behaviour for attribution, because the additional checks of EV mitigate the risks of misissuance.
* What if the user is connecting to a public and untrusted SOCKS5 onion proxy, which is then in a position to forge / rewrite all content, connections, and HTTPS certificates, and present itself as `bar.onion`?

This latter is a real and absolute risk, and (other than via EV certificates) I do not currently see any reasonable way to fix it, but I will point out that untrusted proxies are a deployment architecture actively discouraged by the Tor community. There are services such as [Tor2web](https://www.tor2web.org) which approximate this architecture, but they are deprecated and loudly proclaimed to be insecure. Quote:

> WARNING: Tor2web only protects publishers, not readers. As a reader installing Tor Browser will give you much greater anonymity, confidentiality, and authentication than using Tor2web. Using Tor2web trades off security for convenience and usability.

The notion of having a solitary tor proxy for your entire home is more plausible, but this collapses to the question of where one draws the line of one's own "security perimeter" and how much one trusts that. The recommended deployment architecture for Tor remains having one daemon per host, and for all the apps on that host to talk to it over loopback.

Above I write: *I do not currently see any reasonable way to fix <trust issues regarding connections to an untrusted proxy, by deployment of SSL certificates>* - why is that?  Because if SSL certificates are to resolve trust issues over an untrusted network (eg: *the internet*; or, equally, *accessing onion networks over an untrusted proxy*) then the only way to resolve this is by reference to a trust root that is already established in the browser. 

We already have a mechanism for this: the EV Onion Certificate.

However: the whole point of this proposal is to enable a DV-like Onion Certificate which would complement the self-service nature of Onion Networking.  People create their own onion addresses and use them without requiring the intercession of a third party, and therefore they should be provided with some manner of HTTPS certificate which can also function without the intercession of a third party. 

Traditionally this latter might be a self-signed certificate — because onion addresses are equally self-signed — but rather than create a whole new certificate specification, instead it seems more efficient to simply either:

1. steal the DV specification and then amend it to add "don't act as a CA, and plz ignore the certificate chain", or
2. amend the DV validation rules in a sympathetic way

Hence the above proposal.

Aside from *"fetching the certificate over the onion connection, and narrowing its scope to be relevant only to that onion connection"* - any other proposition to "bind an onion address to a certificate", such as proposing that the certificate be signed by the private key for the onion, runs into technical challenges:

1. what are you going to do with this signature? staple it into the HTTPS protocol somehow? It can't go into the thing that is being signed...
2. with v2 onions, the address is a truncated hash of the public key, rather than the public key itself; lacking the whole 1023-bit public key inhibits validation. Version2 onions are due to be deprecated, but given the above ("source of truth", q.v.) and that no certificate authority exists to be sued for misissuance in a self-service DV onion scenario, I see no reason to exclude them from HTTPS protection.

- Alec Muffett, 10 Feb 2019

[1] ie: individuals can work around it by careful provision of multiple certificates

