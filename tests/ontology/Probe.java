import org.apache.jena.rdf.model.*;
import org.apache.jena.reasoner.ReasonerRegistry;
import org.apache.jena.shacl.*;
import org.apache.jena.vocabulary.*;
import java.io.StringReader;

class Probe {
    static final String NS = "https://fixture.invalid/";
    static Model turtle(String text) {
        Model model = ModelFactory.createDefaultModel();
        model.read(new StringReader(text), NS, "TURTLE");
        return model;
    }
    static void require(boolean condition, String label) {
        if (!condition) throw new AssertionError(label);
    }
    public static void main(String[] args) {
        Model schema = turtle("""
            @prefix f: <https://fixture.invalid/> .
            @prefix owl: <http://www.w3.org/2002/07/owl#> .
            @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
            f:Child a owl:Class ; rdfs:subClassOf f:Parent .
            f:Parent a owl:Class .
            """);
        Model data = turtle("""
            @prefix f: <https://fixture.invalid/> .
            f:item a f:Child ; f:name "Synthetic" .
            """);
        Model inferred = ModelFactory.createInfModel(ReasonerRegistry.getOWLMicroReasoner(), schema, data);
        Resource item = data.createResource(NS + "item");
        Resource parent = data.createResource(NS + "Parent");
        require(!data.contains(item, RDF.type, parent), "source must not contain inferred type");
        require(inferred.contains(item, RDF.type, parent), "OWL Micro subclass inference");
        require(!inferred.contains(data.createResource(NS+"absent"), RDF.type, parent), "unrelated resource inference");
        Model shapesGraph = turtle("""
            @prefix f: <https://fixture.invalid/> .
            @prefix sh: <http://www.w3.org/ns/shacl#> .
            @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
            f:Shape a sh:NodeShape ; sh:targetClass f:Child ;
              sh:property [ sh:path f:name ; sh:minCount 1 ; sh:maxCount 1 ; sh:datatype xsd:string ] .
            """);
        Shapes shapes = Shapes.parse(shapesGraph.getGraph());
        require(ShaclValidator.get().validate(shapes, data.getGraph()).conforms(), "valid data");
        Model bad = turtle("@prefix f: <https://fixture.invalid/> . f:item a f:Child .");
        require(!ShaclValidator.get().validate(shapes, bad.getGraph()).conforms(), "missing property must fail");
        Model wrong = turtle("@prefix f: <https://fixture.invalid/> . f:item a f:Child ; f:name 42 .");
        require(!ShaclValidator.get().validate(shapes, wrong.getGraph()).conforms(), "wrong datatype must fail");
        inferred.close(); schema.close(); data.close(); shapesGraph.close(); bad.close(); wrong.close();
        System.out.println("PASS: isolated OWL Micro inference and SHACL positive/negative validation");
    }
}
