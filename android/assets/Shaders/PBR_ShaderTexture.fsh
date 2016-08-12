//
//  PBR_ShaderTexture.fsh
//
#ifdef GL_ES
precision highp float;
#endif

uniform vec3      vLight0;

varying vec3 eye;
varying vec3 normal;			//NOTE: Need to be high precision
varying vec3 halfvecLight0; 	//NOTE: Need to be high precision

uniform samplerCube sCubemapTexture;

uniform sampler2D albedoTexture;
uniform sampler2D metallicTexture;
uniform sampler2D roughnessTexture;
uniform sampler2D ambientOcclusionTexture;

varying vec2 texCoord;
varying vec3 worldNormal;

#define M_PI 3.1415926535897932384626433832795

vec3 FresnelSchlickWithRoughness(vec3 SpecularColor, vec3 E, vec3 N, float Gloss)
{
	return SpecularColor + (max(vec3(Gloss,Gloss,Gloss), SpecularColor) - SpecularColor) * pow(1.0 - clamp(dot(E, N), 0.0, 1.0), 5.0);
}

void main()
{
    vec3 albedo=texture2D(albedoTexture,texCoord).rgb;
    float metallic=texture2D(metallicTexture,texCoord).r;
    vec3 vMaterialDiffuse=albedo - albedo*metallic;
    vec4 vMaterialSpecular=vec4(mix(albedo, vec3(0.8*0.5),metallic), 10);

    vec2 vRoughness=vec2(1.0-texture2D(roughnessTexture,texCoord).r,5);
    float ambientOcclusion=1-texture2D(ambientOcclusionTexture,texCoord).r;

    vec3 dynamicDiffuse = dot( worldNormal, normalize(-vLight0+eye) ) * vMaterialDiffuse  / 3.14f;

	// Mipmap index
	float MipmapIndex = vRoughness.x * vRoughness.y;	//vRoughness.y = mip-level - 1

	//
	// Diffuse (Lambart)
	//
	//vec3 diffuseEnvColor = textureLod(sCubemapTexture, normal, MipmapIndex).xyz * vMaterialDiffuse / M_PI;
	vec3 diffuseEnvColor = textureCube(sCubemapTexture, normal, MipmapIndex).xyz * vMaterialDiffuse / M_PI;
	//And Dynamic diffuse lighting is done per vertex

	//
	// Specular (Phong + Schlick Fresnel)
    //
    vec3 eyeNormalized = normalize(eye);
    vec3 reflection = reflect(-eyeNormalized, normal);
    float fresnelTerm = pow(1.0 - clamp(dot(eyeNormalized, halfvecLight0), 0.0, 1.0), 5.0);

	// Dynamic Specular
	//NOTE: Need to be high precision
	float NdotH = max(dot(normalize(normal), normalize(halfvecLight0)), 0.0);
    float fPower = exp2(10.0 * (1.0 - vRoughness.x) + 1.0);
    float dynamicSpecular = pow(NdotH, fPower);
	//Normalizing factor for phong
	float normalizeSpecular = (fPower + 1.0) / (M_PI * 2.0);

	dynamicSpecular = (dynamicSpecular + fresnelTerm) * normalizeSpecular;

	//Envmap Specular

	//Fresnel equation for pre-filtered envmap
	//http://seblagarde.wordpress.com/2011/08/17/hello-world/
	vec3 fresnel = FresnelSchlickWithRoughness(vMaterialSpecular.xyz, eyeNormalized, normal, 1.0 - vRoughness.x);
	//vec3 specularEnvColor = textureLod(sCubemapTexture, reflection, MipmapIndex).xyz * fresnel;
	vec3 specularEnvColor = textureCube(sCubemapTexture, reflection, MipmapIndex).xyz * fresnel;
	//linearise
	//specularEnvColor.xyz = pow(specularEnvColor.xyz, vec3(2.2,2.2,2.2));

	gl_FragColor = vec4(dynamicSpecular * vMaterialSpecular.xyz + ambientOcclusion * dynamicDiffuse
					+ ambientOcclusion * diffuseEnvColor + (0.3+0.7*ambientOcclusion) * specularEnvColor, 1.0);

	//
	// Gamma conversion
	//fragmentColor.xyz = pow(fragmentColor.xyz, vec3(1.0/1.8, 1.0/1.8, 1.0/1.8));
}
