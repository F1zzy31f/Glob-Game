import React, { useRef, useState } from "react";
import { Button, Card, Form, Alert } from "react-bootstrap";
import { Link } from "react-router-dom";

export default function ChangeDisplayName() {
  const displayNameRef = useRef();

  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [currentDisplayName] = useState("");

  async function handleSubmit(e) {
    e.preventDefault();

    try {
      setError("");
      setLoading(true);

      throw error;
    } catch {
      setError("Failed to change display name");
    }

    setLoading(false);
  }

  return (
    <>
      <Card>
        <Card.Body>
          <h2 className="text-center mb-4">Change display name</h2>
          {error && <Alert variant="danger">{error}</Alert>}
          <strong>Current display name: </strong> {currentDisplayName}
          <Form onSubmit={handleSubmit}>
            <Form.Group id="displayName" className="mb-2 mt-4">
              <Form.Label>New display name</Form.Label>
              <Form.Control type="text" ref={displayNameRef} required />
            </Form.Group>
            <Button disabled={loading} className="w-100" type="submit">
              Submit
            </Button>
          </Form>
        </Card.Body>
      </Card>
      <div className="w-100 text-center mt-2">
        <Link to="/" className="w-100 mt-4">
          Back to Dashboard
        </Link>
      </div>
    </>
  );
}
