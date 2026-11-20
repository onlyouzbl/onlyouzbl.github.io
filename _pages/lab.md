---
layout: lab
permalink: /lab/
title: LIN-AI Lab
description: The Multimodal Understanding and Retrieval Lab at Ningbo University, led by Bolin Zhang.
---

<section id="about" class="intro" aria-labelledby="about-heading">
  <img src="/assets/img/lin-ai-lab.svg" width="1400" height="580" alt="LIN-AI Lab · 麟智实验室">
  <div>
    <h2 id="about-heading">About the Lab</h2>
    <p>The Multimodal Understanding and Retrieval Lab (LIN-AI Lab) was founded at Ningbo University on <time datetime="2026-11-05">November 5, 2026</time>. Led by <a href="/">Bolin Zhang</a>, the lab focuses on multimodal retrieval. We study how a query in one form, such as a sentence, can help us find relevant information in another, such as a video.</p>
    <p class="motto"><em>Bringing talent together, shaping the future through intelligence.</em> <span lang="zh-CN">麟聚英才，智启未来</span></p>
  </div>
</section>

<section id="members" aria-labelledby="members-heading">
  <h2 id="members-heading">Lab Members</h2>
  <div class="lab-lead">
    <h3><a href="/">Bolin Zhang <span lang="zh-CN">张博麟</span></a></h3>
    <p>Lab Director</p>
    <p><strong>Research interests</strong> · Multimodal retrieval and video moment retrieval from large video collections.</p>
  </div>
  <div class="cohort">
    <div><h3>Students</h3><p>Entered <time datetime="2026-09">September 2026</time></p></div>
    <div class="students">
      {% for slot in (1..2) %}
      <div class="student">
        <div class="student-photo" aria-label="Student photo, pending" role="img"></div>
        <dl>
          <dt>English name</dt><dd></dd>
          <dt>Chinese name</dt><dd></dd>
          <dt>Research interests</dt><dd></dd>
        </dl>
      </div>
      {% endfor %}
    </div>
  </div>
</section>

<section id="research">
  <h2>Research Areas</h2>
  <h3>Video Moment Retrieval from Large Video Collections</h3>
  <p>Given a description such as “a person pushes a bicycle across the street,” we want to find both the right video in a collection and the exact interval it describes. We study how to distinguish similar actions and learn their boundaries when training examples have captions but no timestamps.</p>
  <h3>Video Anomaly Detection</h3>
  <p>We study how to identify moments in long recordings that warrant a closer look. Context matters: running on a track may mean something different from running through a crowded station.</p>
  <h3>Spiking Neural Networks for Video</h3>
  <p>Consecutive frames often contain much of the same information. We explore whether spiking neural networks can reduce computation by responding to changes while retaining the cues needed to recognize an event.</p>
</section>

<section id="publications">
  <h2>Publications</h2>
  <p><a href="/#publications">Browse Bolin Zhang’s publications</a></p>
</section>
